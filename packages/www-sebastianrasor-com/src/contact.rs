mod message;
mod proof;
mod rate_limit;

use std::sync::Arc;

use axum::{
    Router,
    extract::{DefaultBodyLimit, FromRef, State, rejection::JsonRejection},
    http::{StatusCode, header},
    response::{IntoResponse, NoContent, Response},
    routing::post,
};
use hickory_resolver::{
    TokioAsyncResolver,
    config::{ResolverConfig, ResolverOpts},
    error::ResolveError,
};
use lettre::{
    Address, AsyncSmtpTransport, AsyncTransport, Tokio1Executor, message::Mailbox,
    transport::smtp::AsyncSmtpTransportBuilder,
};
use problem_details::ProblemDetails;
use serde::{Deserialize, Deserializer};

use self::{
    message::ContactMessage,
    proof::{Challenger, VerifiedProof},
    rate_limit::{ClientSubnet, GlobalQuota, SendCooldowns},
};

const MAX_BODY_LIMIT_BYTES: usize = 64 * 1024;

#[derive(Deserialize)]
#[cfg_attr(debug_assertions, serde(default))]
pub struct Config {
    #[serde(default = "default_from_address")]
    from_address: Address,
    #[serde(
        rename = "smtp_connection_url",
        deserialize_with = "deserialize_smtp_transport"
    )]
    sender: AsyncSmtpTransport<Tokio1Executor>,
    to_mailbox: Mailbox,
}

fn default_from_address() -> Address {
    Address::new_dangerous("noreply", "www.sebastianrasor.com")
}

fn deserialize_smtp_transport<'de, D>(
    deserializer: D,
) -> Result<AsyncSmtpTransport<Tokio1Executor>, D::Error>
where
    D: Deserializer<'de>,
{
    let url = String::deserialize(deserializer)?;
    AsyncSmtpTransport::<Tokio1Executor>::from_url(&url)
        .map(AsyncSmtpTransportBuilder::build)
        .map_err(serde::de::Error::custom)
}

#[cfg(debug_assertions)]
impl Default for Config {
    fn default() -> Self {
        Self {
            from_address: default_from_address(),
            sender: AsyncSmtpTransport::<Tokio1Executor>::from_url(
                "smtp://noreply:password1@localhost:1025",
            )
            .expect("default debug SMTP URL is valid")
            .build(),
            to_mailbox: Mailbox::new(
                Some("Sebastian Rasor".to_string()),
                Address::new_dangerous("sebastian", "test"),
            ),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, thiserror::Error)]
enum Field {
    #[error("From header")]
    From,
    #[error("From display name")]
    FromName,
    #[error("Subject header")]
    Subject,
    #[error("message body")]
    Body,
}

#[derive(Debug, thiserror::Error)]
enum ContactError {
    #[error("Mail challenge expired or invalid. Please try sending again.")]
    InvalidChallenge,
    #[error("Too many messages received recently. Please try again later.")]
    RateLimited,
    #[error(transparent)]
    Json(#[from] JsonRejection),
    #[error("The {0} is required.")]
    MissingField(Field),
    #[error("Multiple {0}s are not allowed.")]
    DuplicateHeader(Field),
    #[error("The {0} exceeds the maximum allowed length.")]
    FieldTooLong(Field),
    #[error("Invalid sender email address.")]
    InvalidEmail,
    #[error(transparent)]
    Smtp(#[from] lettre::transport::smtp::Error),
    #[error(transparent)]
    DnsLookup(#[from] Box<ResolveError>),
    #[error(transparent)]
    DnsTimeout(#[from] tokio::time::error::Elapsed),
}

impl IntoResponse for ContactError {
    fn into_response(self) -> Response {
        let (status, detail) = match self {
            Self::InvalidChallenge => (StatusCode::FORBIDDEN, self.to_string()),
            Self::RateLimited => (StatusCode::TOO_MANY_REQUESTS, self.to_string()),
            Self::Json(rejection) => (rejection.status(), rejection.body_text()),
            Self::MissingField(_)
            | Self::DuplicateHeader(_)
            | Self::FieldTooLong(_)
            | Self::InvalidEmail => (StatusCode::UNPROCESSABLE_ENTITY, self.to_string()),
            Self::Smtp(_) | Self::DnsLookup(_) | Self::DnsTimeout(_) => {
                tracing::error!(error = %self, "failed to process mail submission");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "The server was unable to complete your request. Please try again later."
                        .to_string(),
                )
            }
        };

        ProblemDetails::from_status_code(status)
            .with_detail(detail)
            .into_response()
    }
}

struct AppState {
    config: Config,
    resolver: TokioAsyncResolver,
    challenger: Challenger,
    cooldowns: SendCooldowns,
    global_quota: GlobalQuota,
}

impl FromRef<Arc<AppState>> for Challenger {
    fn from_ref(state: &Arc<AppState>) -> Self {
        state.challenger.clone()
    }
}

impl AppState {
    async fn deliver(&self, msg: ContactMessage) -> Result<NoContent, ContactError> {
        if !msg.sender_domain().accepts_mail(&self.resolver).await? {
            return Err(ContactError::InvalidEmail);
        }

        self.global_quota.acquire()?;
        let email = msg.into_email(
            self.config.from_address.clone(),
            self.config.to_mailbox.clone(),
        );
        self.config.sender.send(email).await?;
        Ok(NoContent)
    }
}

pub fn app(config: Config) -> Router {
    let resolver = TokioAsyncResolver::tokio_from_system_conf().unwrap_or_else(|_| {
        TokioAsyncResolver::tokio(ResolverConfig::default(), ResolverOpts::default())
    });

    let state = Arc::new(AppState {
        config,
        resolver,
        challenger: Challenger::new(),
        cooldowns: SendCooldowns::new(),
        global_quota: GlobalQuota::new(),
    });

    let router = Router::new()
        .route(
            "/contact",
            post(submit).get(issue_challenge).with_state(state),
        )
        .layer(DefaultBodyLimit::max(MAX_BODY_LIMIT_BYTES));

    rate_limit::apply_governors(router)
}

async fn issue_challenge(
    State(challenger): State<Challenger>,
    subnet: ClientSubnet,
) -> impl IntoResponse {
    (
        [(header::CACHE_CONTROL, "no-store")],
        challenger.issue(subnet),
    )
}

async fn submit(
    State(state): State<Arc<AppState>>,
    proof: VerifiedProof,
    msg: ContactMessage,
) -> Result<NoContent, ContactError> {
    state
        .cooldowns
        .run(proof.subnet(), state.deliver(msg))
        .await
}
