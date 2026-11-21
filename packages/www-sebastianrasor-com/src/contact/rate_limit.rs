use std::{
    fmt,
    future::{self, Future},
    net::{IpAddr, SocketAddr},
    num::NonZeroU32,
    time::Duration,
};

use axum::{
    Router,
    extract::{ConnectInfo, FromRequestParts},
    http::{Extensions, HeaderMap, Method, Request, request::Parts},
};
use governor::{DefaultDirectRateLimiter, Quota, RateLimiter};
use ipnet::{IpNet, Ipv4Net, Ipv6Net};
use moka::sync::Cache;
use scopeguard::ScopeGuard;
use tower_governor::{
    GovernorError, GovernorLayer, governor::GovernorConfigBuilder, key_extractor::KeyExtractor,
};

use super::ContactError;

const SEND_COOLDOWN: Duration = Duration::from_mins(10);
const GOVERNOR_CLEANUP_INTERVAL: Duration = Duration::from_mins(1);
const MAX_COOLDOWN_ENTRIES: u64 = 4096;
const GET_RATE_LIMIT_PERIOD: Duration = Duration::from_secs(10);
const GET_RATE_LIMIT_BURST: u32 = 6;
const POST_RATE_LIMIT_PERIOD: Duration = Duration::from_mins(10);
const POST_RATE_LIMIT_BURST: u32 = 3;
const GLOBAL_SEND_HOURLY_QUOTA: NonZeroU32 = NonZeroU32::new(15).expect("non-zero quota");
const REAL_IP_HEADER: &str = "x-real-ip";

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub(super) struct ClientSubnet(IpNet);

impl ClientSubnet {
    pub(super) fn from_ip(ip: IpAddr) -> Self {
        let net = match ip.to_canonical() {
            IpAddr::V4(v4) => IpNet::V4(Ipv4Net::from(v4)),
            IpAddr::V6(v6) => IpNet::V6(Ipv6Net::new_assert(v6, 64).trunc()),
        };
        Self(net)
    }

    fn extract(headers: &HeaderMap, peer_ip: Option<IpAddr>) -> Option<Self> {
        let real_ip = if peer_ip.is_some_and(|ip| ip.is_loopback()) {
            headers
                .get(REAL_IP_HEADER)
                .and_then(|hv| hv.to_str().ok())
                .and_then(|s| s.trim().parse::<IpAddr>().ok())
                .or(peer_ip)
        } else {
            peer_ip
        };
        real_ip.map(Self::from_ip)
    }

    fn from_request(headers: &HeaderMap, extensions: &Extensions) -> Option<Self> {
        let peer_ip = extensions
            .get::<ConnectInfo<SocketAddr>>()
            .map(|ConnectInfo(addr)| addr.ip());
        Self::extract(headers, peer_ip)
    }
}

impl From<IpAddr> for ClientSubnet {
    fn from(ip: IpAddr) -> Self {
        Self::from_ip(ip)
    }
}

impl fmt::Display for ClientSubnet {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.0.fmt(f)
    }
}

impl<S: Send + Sync> FromRequestParts<S> for ClientSubnet {
    type Rejection = ContactError;

    fn from_request_parts(
        parts: &mut Parts,
        _state: &S,
    ) -> impl Future<Output = Result<Self, Self::Rejection>> + Send {
        future::ready(
            Self::from_request(&parts.headers, &parts.extensions)
                .ok_or(ContactError::InvalidChallenge),
        )
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct SubnetKeyExtractor;

impl KeyExtractor for SubnetKeyExtractor {
    type Key = ClientSubnet;

    fn extract<T>(&self, req: &Request<T>) -> Result<Self::Key, GovernorError> {
        ClientSubnet::from_request(req.headers(), req.extensions())
            .ok_or(GovernorError::UnableToExtractKey)
    }
}

pub(super) fn apply_governors(router: Router) -> Router {
    let [get_governor, post_governor] = [
        (Method::GET, GET_RATE_LIMIT_PERIOD, GET_RATE_LIMIT_BURST),
        (Method::POST, POST_RATE_LIMIT_PERIOD, POST_RATE_LIMIT_BURST),
    ]
    .map(|(method, period, burst)| {
        GovernorConfigBuilder::default()
            .period(period)
            .burst_size(burst)
            .methods(vec![method])
            .key_extractor(SubnetKeyExtractor)
            .finish()
            .expect("governor config is always valid")
    });

    if let Ok(handle) = tokio::runtime::Handle::try_current() {
        let get_limiter = get_governor.limiter().clone();
        let post_limiter = post_governor.limiter().clone();
        handle.spawn(async move {
            let mut interval = tokio::time::interval(GOVERNOR_CLEANUP_INTERVAL);
            loop {
                interval.tick().await;
                get_limiter.retain_recent();
                post_limiter.retain_recent();
            }
        });
    }

    router
        .layer(GovernorLayer::new(get_governor))
        .layer(GovernorLayer::new(post_governor))
}

pub(super) struct SendCooldowns(Cache<ClientSubnet, ()>);

impl SendCooldowns {
    pub(super) fn new() -> Self {
        Self(
            Cache::builder()
                .max_capacity(MAX_COOLDOWN_ENTRIES)
                .time_to_live(SEND_COOLDOWN)
                .build(),
        )
    }

    pub(super) async fn run<T, F>(&self, subnet: ClientSubnet, fut: F) -> Result<T, ContactError>
    where
        F: Future<Output = Result<T, ContactError>>,
    {
        if !self.0.entry(subnet).or_insert(()).is_fresh() {
            return Err(ContactError::RateLimited);
        }
        let guard = scopeguard::guard((), |()| self.0.invalidate(&subnet));
        let out = fut.await?;
        ScopeGuard::into_inner(guard);
        Ok(out)
    }
}

pub(super) struct GlobalQuota(DefaultDirectRateLimiter);

impl GlobalQuota {
    pub(super) fn new() -> Self {
        Self(RateLimiter::direct(Quota::per_hour(
            GLOBAL_SEND_HOURLY_QUOTA,
        )))
    }

    pub(super) fn acquire(&self) -> Result<(), ContactError> {
        self.0.check().map_err(|_| ContactError::RateLimited)
    }
}

#[cfg(test)]
mod tests {
    use std::net::Ipv4Addr;

    use super::*;

    #[test]
    fn normalizes_ipv6_to_64_and_ignores_spoofed_headers() {
        let mut headers = HeaderMap::new();
        headers.insert("x-forwarded-for", "1.2.3.4".parse().unwrap());
        headers.insert("x-real-ip", "2001:db8:abcd:1234:5678::1".parse().unwrap());

        let external_peer = Some(IpAddr::V4(Ipv4Addr::new(198, 51, 100, 7)));
        assert_eq!(
            ClientSubnet::extract(&headers, external_peer),
            external_peer.map(ClientSubnet::from_ip)
        );

        let loopback_peer = Some(IpAddr::V4(Ipv4Addr::LOCALHOST));
        let extracted = ClientSubnet::extract(&headers, loopback_peer).unwrap();
        assert_eq!(
            extracted,
            ClientSubnet::from_ip("2001:db8:abcd:1234:ffff::99".parse().unwrap())
        );
        assert_eq!(extracted.to_string(), "2001:db8:abcd:1234::/64");
    }

    #[tokio::test]
    async fn cooldown_rolls_back_on_error_or_cancel_until_success() {
        let subnet_a = ClientSubnet::from_ip("2001:db8:abcd:1234::99".parse().unwrap());
        let subnet_b = ClientSubnet::from_ip("198.51.100.7".parse().unwrap());
        let cooldowns = SendCooldowns::new();

        // Returning Err rolls back the cooldown automatically.
        assert!(matches!(
            cooldowns
                .run(
                    subnet_a,
                    future::ready(Err::<(), _>(ContactError::InvalidEmail))
                )
                .await,
            Err(ContactError::InvalidEmail)
        ));

        // Dropping an in-flight run mid-await also rolls back the cooldown.
        tokio::select! {
            biased;
            res = cooldowns.run(subnet_a, async {
                assert!(matches!(
                    cooldowns.run(subnet_a, future::ready(Ok(()))).await,
                    Err(ContactError::RateLimited)
                ));
                future::pending::<Result<(), ContactError>>().await
            }) => panic!("pending future should not resolve: {res:?}"),
            () = future::ready(()) => {}
        }

        // After rollback, subnet_a can succeed and commit its cooldown.
        cooldowns
            .run(subnet_a, future::ready(Ok(())))
            .await
            .unwrap();
        assert!(matches!(
            cooldowns.run(subnet_a, future::ready(Ok(()))).await,
            Err(ContactError::RateLimited)
        ));
        assert!(cooldowns.run(subnet_b, future::ready(Ok(()))).await.is_ok());
    }
}
