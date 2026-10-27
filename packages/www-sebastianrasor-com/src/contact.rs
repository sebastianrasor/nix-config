use std::{error::Error, sync::Arc, time::Duration};

use axum::{
    Router,
    extract::{Form, State, rejection::FormRejection},
    http::{HeaderMap, StatusCode, header},
    response::{IntoResponse, NoContent, Response},
    routing::post,
};
use check_if_email_exists::{
    CheckEmailInput, check_email,
    smtp::{SmtpError, verif_method::VerifMethod},
};
use fernet::Fernet;
use lettre::{
    Address, AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor,
    message::{Mailbox, header::ContentType},
};
use moka::sync::Cache;
use problem_details::ProblemDetails;
use serde::{Deserialize, Serialize};

const DELIVERABILITY_CHECK_TIMEOUT: Duration = Duration::from_secs(10);
const TIMESTAMP_TTL: Duration = Duration::from_hours(1);
const MIN_SUBMISSION_DELAY: Duration = Duration::from_secs(5);
const TIMESTAMP_HEADER: &str = "x-timestamp";

#[derive(Deserialize)]
#[cfg_attr(debug_assertions, serde(default))]
pub struct Config {
    #[serde(default = "default_from_address")]
    from_address: Address,
    smtp_connection_url: String,
    to_mailbox: Mailbox,
}

fn default_from_address() -> Address {
    Address::new_dangerous("noreply", "sebastianrasor.com")
}

#[cfg(debug_assertions)]
impl Default for Config {
    fn default() -> Self {
        Self {
            from_address: default_from_address(),
            smtp_connection_url: "smtp://noreply:password1@localhost:1025".to_string(),
            to_mailbox: Mailbox::new(
                Some("Sebastian Rasor".to_string()),
                Address::new_dangerous("sebastian", "test"),
            ),
        }
    }
}

struct AppState {
    from_address: Address,
    to_mailbox: Mailbox,
    verif_method: VerifMethod,
    sender: AsyncSmtpTransport<Tokio1Executor>,
    fernet: Fernet,
    spent_tokens: Cache<String, ()>,
}

#[derive(Deserialize)]
struct Submission {
    #[serde(rename(deserialize = "given-name"))]
    honeypot: Option<String>,
    #[serde(rename(deserialize = "family-name"))]
    name: Option<String>,
    email: Option<String>,
    message: Option<String>,
}

#[derive(Debug, thiserror::Error)]
enum ContactError {
    #[error("Form session expired or invalid. Please reload the page and try again.")]
    InvalidTimestamp,
    #[error(transparent)]
    Form(#[from] FormRejection),
    #[error("The {0} field is required.")]
    MissingField(&'static str),
    #[error("Invalid email address.")]
    InvalidEmail,
    #[error(transparent)]
    Smtp(#[from] lettre::transport::smtp::Error),
    #[error(transparent)]
    SmtpVerification(#[from] SmtpError),
}

#[derive(Serialize)]
struct ProblemExt {
    #[serde(skip_serializing_if = "Option::is_none")]
    field: Option<&'static str>,
}

impl IntoResponse for ContactError {
    fn into_response(self) -> Response {
        let (status, detail, field) = match self {
            Self::InvalidTimestamp => (StatusCode::FORBIDDEN, self.to_string(), None),
            Self::Form(rejection) => (rejection.status(), rejection.body_text(), None),
            Self::MissingField(field) => (
                StatusCode::UNPROCESSABLE_ENTITY,
                self.to_string(),
                Some(field),
            ),
            Self::InvalidEmail => (
                StatusCode::UNPROCESSABLE_ENTITY,
                self.to_string(),
                Some("email"),
            ),
            Self::Smtp(_) | Self::SmtpVerification(_) => {
                tracing::error!(error = %self, "failed to process contact form submission");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "The server was unable to complete your request. Please try again later."
                        .to_string(),
                    None,
                )
            }
        };

        ProblemDetails::from_status_code(status)
            .with_detail(detail)
            .with_extensions(ProblemExt { field })
            .into_response()
    }
}

pub fn app(config: Config) -> Result<Router, Box<dyn Error>> {
    let sender =
        AsyncSmtpTransport::<Tokio1Executor>::from_url(&config.smtp_connection_url)?.build();
    let verif_method = VerifMethod::new_with_same_config_for_all(
        None,
        hostname::get()?.to_string_lossy().into_owned(),
        config.from_address.to_string(),
        lettre::transport::smtp::SMTP_PORT,
        Some(DELIVERABILITY_CHECK_TIMEOUT),
        0,
    );
    let state = Arc::new(AppState {
        from_address: config.from_address,
        to_mailbox: config.to_mailbox,
        verif_method,
        sender,
        fernet: Fernet::new(&Fernet::generate_key()).expect("generated key is always valid"),
        spent_tokens: Cache::builder().time_to_live(TIMESTAMP_TTL).build(),
    });

    Ok(Router::new().route(
        "/contact",
        post(submit).get(issue_timestamp).with_state(state),
    ))
}

async fn issue_timestamp(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    (
        [(header::CACHE_CONTROL, "no-store")],
        state.fernet.encrypt(b""),
    )
}

async fn submit(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    form: Result<Form<Submission>, FormRejection>,
) -> Result<NoContent, ContactError> {
    let token = headers
        .get(TIMESTAMP_HEADER)
        .and_then(|value| value.to_str().ok())
        .filter(|&token| {
            state
                .fernet
                .decrypt_with_ttl(token, TIMESTAMP_TTL.as_secs())
                .is_ok()
                && state
                    .spent_tokens
                    .entry_by_ref(token)
                    .or_insert(())
                    .is_fresh()
        })
        .ok_or(ContactError::InvalidTimestamp)?;

    async {
        let Form(submission) = form?;

        if state
            .fernet
            .decrypt_with_ttl(token, MIN_SUBMISSION_DELAY.as_secs())
            .is_ok()
            || submission
                .honeypot
                .is_some_and(|honeypot| !honeypot.is_empty())
        {
            return Ok(NoContent);
        }

        let name = required(submission.name, "name")?;
        let email: Address = required(submission.email, "email")?
            .parse()
            .map_err(|_| ContactError::InvalidEmail)?;
        let body = required(submission.message, "message")?;

        let deliverability_check = CheckEmailInput {
            to_email: email.to_string(),
            verif_method: state.verif_method.clone(),
            ..Default::default()
        };
        if !check_email(&deliverability_check)
            .await
            .smtp?
            .is_deliverable
        {
            return Err(ContactError::InvalidEmail);
        }

        let message = Message::builder()
            .from(Mailbox::new(Some(name.clone()), state.from_address.clone()))
            .reply_to(Mailbox::new(Some(name), email))
            .to(state.to_mailbox.clone())
            .subject("Contact Form Submission")
            .header(ContentType::TEXT_PLAIN)
            .body(body)
            .expect("from and to are always set");

        state.sender.send(message).await?;

        Ok(NoContent)
    }
    .await
    .inspect_err(|_| state.spent_tokens.invalidate(token))
}

fn required(value: Option<String>, field: &'static str) -> Result<String, ContactError> {
    value
        .filter(|value| !value.trim().is_empty())
        .ok_or(ContactError::MissingField(field))
}
