mod message;
mod smtp;

use std::{
    future::{Future, ready},
    net::{IpAddr, SocketAddr},
    num::{NonZeroU32, NonZeroU64},
    sync::Arc,
    time::Duration,
};

use axum::{
    Router,
    extract::{ConnectInfo, FromRequestParts, State, WebSocketUpgrade},
    http::{StatusCode, request::Parts},
    response::IntoResponse,
    routing::any,
};
use governor::{DefaultKeyedRateLimiter, Quota, RateLimiter, clock::Clock};
use hickory_resolver::{
    TokioResolver,
    config::{CLOUDFLARE, ResolverConfig},
    net::{NetError, runtime::TokioRuntimeProvider},
};
use lettre::{Address, AsyncSmtpTransport, AsyncTransport, Tokio1Executor, message::Mailbox};
use serviceconf::ServiceConf;

use self::message::{ParseError, Submission};

const DEFAULT_FROM_ADDRESS: &str = "noreply@www.sebastianrasor.com";
#[cfg(any(debug_assertions, test))]
const DEFAULT_SMTP_URL: &str = "smtp://noreply:password1@localhost:1025";
#[cfg(any(debug_assertions, test))]
const DEFAULT_TO_MAILBOX: &str = "Sebastian Rasor <sebastian@test>";

type SmtpSender = AsyncSmtpTransport<Tokio1Executor>;

fn parse_smtp_url(url: &str) -> Result<SmtpSender, lettre::transport::smtp::Error> {
    SmtpSender::from_url(url).map(|b| b.timeout(Some(Duration::from_secs(15))).build())
}

#[derive(ServiceConf)]
#[conf(prefix = "WWW_")]
pub struct Config {
    #[conf(from_file, default = DEFAULT_FROM_ADDRESS.parse().expect("static address is valid"))]
    from_address: Address,
    #[conf(
        name = "SMTP_CONNECTION_URL",
        from_file,
        deserializer = "parse_smtp_url"
    )]
    #[cfg_attr(any(debug_assertions, test), conf(default = parse_smtp_url(DEFAULT_SMTP_URL).expect("static SMTP URL is valid")))]
    sender: SmtpSender,
    #[conf(from_file)]
    #[cfg_attr(any(debug_assertions, test), conf(default = DEFAULT_TO_MAILBOX.parse().expect("static mailbox is valid")))]
    to_mailbox: Mailbox,
}

#[cfg(test)]
impl Default for Config {
    fn default() -> Self {
        Self {
            from_address: DEFAULT_FROM_ADDRESS
                .parse()
                .expect("static address is valid"),
            sender: parse_smtp_url(DEFAULT_SMTP_URL).expect("static SMTP URL is valid"),
            to_mailbox: DEFAULT_TO_MAILBOX.parse().expect("static mailbox is valid"),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct ClientIp(IpAddr);

impl<S: Send + Sync> FromRequestParts<S> for ClientIp {
    type Rejection = StatusCode;

    fn from_request_parts(
        parts: &mut Parts,
        _state: &S,
    ) -> impl Future<Output = Result<Self, Self::Rejection>> + Send {
        let mut real_ip = parts.headers.get_all("x-real-ip").iter();
        let res = match (real_ip.next(), real_ip.next()) {
            (Some(v), None) => v
                .to_str()
                .ok()
                .and_then(|s| s.trim().parse::<IpAddr>().ok())
                .ok_or(StatusCode::BAD_REQUEST),
            (Some(_), Some(_)) => Err(StatusCode::BAD_REQUEST),
            (None, _) => parts
                .extensions
                .get::<ConnectInfo<SocketAddr>>()
                .map(|c| c.ip())
                .ok_or(StatusCode::INTERNAL_SERVER_ERROR),
        };
        ready(res.map(|ip| Self(ip.to_canonical())))
    }
}

#[derive(Debug, thiserror::Error)]
enum Error {
    #[error(transparent)]
    Invalid(#[from] ParseError),
    #[error("Too many messages sent recently. Please try again in {0}s.")]
    RateLimited(NonZeroU64),
    #[error("Unable to verify sender email domain via DNS. Please try again later.")]
    Dns(#[source] NetError),
    #[error("The server was unable to complete your request. Please try again later.")]
    Smtp(#[from] lettre::transport::smtp::Error),
}

struct AppState {
    config: Config,
    resolver: TokioResolver,
    limiter: DefaultKeyedRateLimiter<ClientIp>,
}

pub fn app(config: Config) -> Result<Router, NetError> {
    let mut resolver_builder = TokioResolver::builder_tokio().unwrap_or_else(|_| {
        TokioResolver::builder_with_config(
            ResolverConfig::udp_and_tcp(&CLOUDFLARE),
            TokioRuntimeProvider::default(),
        )
    });
    resolver_builder.options_mut().timeout = Duration::from_secs(5);
    resolver_builder.options_mut().attempts = 1;

    let quota = Quota::per_hour(const { NonZeroU32::new(12).unwrap() })
        .allow_burst(const { NonZeroU32::new(2).unwrap() });
    let state = Arc::new(AppState {
        config,
        resolver: resolver_builder.build()?,
        limiter: RateLimiter::keyed(quota),
    });

    Ok(Router::new()
        .route("/contact", any(ws_contact))
        .with_state(state))
}

#[allow(clippy::unused_async)]
async fn ws_contact(
    State(state): State<Arc<AppState>>,
    ws: WebSocketUpgrade,
    client_ip: ClientIp,
) -> impl IntoResponse {
    ws.max_message_size(smtp::MAX_WS_FRAME_BYTES)
        .max_frame_size(smtp::MAX_WS_FRAME_BYTES)
        .on_upgrade(move |socket| smtp::serve(socket, state, client_ip))
}

async fn deliver(state: &AppState, client_ip: ClientIp, raw_msg: &[u8]) -> Result<(), Error> {
    let submission = Submission::parse(raw_msg)?;

    if state.limiter.len() > 1024 {
        state.limiter.retain_recent();
    }
    state.limiter.check_key(&client_ip).map_err(|not_until| {
        let wait = not_until.wait_time_from(state.limiter.clock().now());
        let secs = wait
            .as_secs()
            .saturating_add(u64::from(wait.subsec_nanos() > 0));
        Error::RateLimited(NonZeroU64::new(secs).unwrap_or(NonZeroU64::MIN))
    })?;

    let message = submission
        .verify_dns(&state.resolver, &state.config)
        .await?;
    state
        .config
        .sender
        .send(message)
        .await
        .inspect_err(|err| tracing::error!(error = %err, "failed to process mail submission"))?;
    Ok(())
}
