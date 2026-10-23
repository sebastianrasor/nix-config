use std::{error::Error, sync::Arc, time::Duration};

use axum::{
    Router,
    extract::{Form, State, rejection::FormRejection},
    http::StatusCode,
    response::{IntoResponse, NoContent, Response},
    routing::post,
};
use axum_turnstile::TurnstileLayer;
use check_if_email_exists::{
    CheckEmailInput, check_email,
    smtp::{SmtpError, verif_method::VerifMethod},
};
use lettre::{
    Address, AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor,
    message::{Mailbox, header::ContentType},
};
use problem_details::ProblemDetails;
use serde::{Deserialize, Serialize};

const DELIVERABILITY_CHECK_TIMEOUT: Duration = Duration::from_secs(10);

/// Contact form settings.
///
/// Credentials and the recipient only have defaults in debug builds, so a release build
/// refuses to start instead of silently falling back to development values.
#[derive(Deserialize)]
#[cfg_attr(debug_assertions, serde(default))]
pub struct Config {
    #[serde(default)]
    confirm_deliverability: bool,
    #[serde(default = "default_from_address")]
    from_address: Address,
    smtp_connection_url: String,
    to_mailbox: Mailbox,
    turnstile_secret_key: String,
}

fn default_from_address() -> Address {
    Address::new_dangerous("noreply", "sebastianrasor.com")
}

/// Development defaults: the Mailpit server from `shell.nix` and Cloudflare's always-pass
/// Turnstile test secret.
#[cfg(debug_assertions)]
impl Default for Config {
    fn default() -> Self {
        Self {
            confirm_deliverability: false,
            from_address: default_from_address(),
            smtp_connection_url: "smtp://noreply:password1@localhost:1025".to_string(),
            to_mailbox: Mailbox::new(
                Some("Sebastian Rasor".to_string()),
                Address::new_dangerous("sebastian", "test"),
            ),
            turnstile_secret_key: "1x0000000000000000000000000000000AA".to_string(),
        }
    }
}

enum Deliverability {
    Enabled { hello_name: String },
    Disabled,
}

struct AppState {
    from_address: Address,
    to_mailbox: Mailbox,
    deliverability: Deliverability,
    sender: AsyncSmtpTransport<Tokio1Executor>,
}

pub fn app(config: Config) -> Result<Router, Box<dyn Error>> {
    let sender =
        AsyncSmtpTransport::<Tokio1Executor>::from_url(&config.smtp_connection_url)?.build();

    let deliverability = if config.confirm_deliverability {
        Deliverability::Enabled {
            hello_name: hostname::get()?.to_string_lossy().into_owned(),
        }
    } else {
        Deliverability::Disabled
    };

    let turnstile = TurnstileLayer::from_secret(&config.turnstile_secret_key);
    let state = Arc::new(AppState {
        from_address: config.from_address,
        to_mailbox: config.to_mailbox,
        deliverability,
        sender,
    });

    Ok(Router::new().route("/contact", post(handler).with_state(state).layer(turnstile)))
}

async fn handler(
    State(state): State<Arc<AppState>>,
    submission: Result<Form<RawSubmission>, FormRejection>,
) -> Result<NoContent, ContactError> {
    let Form(submission) = submission?;
    let submission = Submission::try_from(submission)?;

    if let Deliverability::Enabled { hello_name } = &state.deliverability
        && !is_address_deliverable(&submission.email, &state.from_address, hello_name).await?
    {
        return Err(ContactError::InvalidEmail);
    }

    let message = submission.into_message(&state.from_address, &state.to_mailbox);
    state.sender.send(message).await?;

    Ok(NoContent)
}

/// The submission as it arrives over the wire.
///
/// Every field is an optional string and is validated in [`Submission::try_from`], so each
/// error can name the field it applies to; serde's own errors are only available as
/// messages.
#[derive(Deserialize)]
struct RawSubmission {
    message: Option<String>,
    email: Option<String>,
    name: Option<String>,
}

struct Submission {
    message: String,
    email: Address,
    name: String,
}

impl TryFrom<RawSubmission> for Submission {
    type Error = ContactError;

    fn try_from(raw: RawSubmission) -> Result<Self, Self::Error> {
        /// Blank (empty or whitespace-only) values count as missing.
        fn required(value: Option<String>, field: &'static str) -> Result<String, ContactError> {
            value
                .filter(|value| !value.trim().is_empty())
                .ok_or(ContactError::MissingField(field))
        }

        Ok(Self {
            message: required(raw.message, "message")?,
            email: required(raw.email, "email")?
                .parse()
                .map_err(|_| ContactError::InvalidEmail)?,
            name: required(raw.name, "name")?,
        })
    }
}

impl Submission {
    fn into_message(self, from_address: &Address, to_mailbox: &Mailbox) -> Message {
        Message::builder()
            .from(Mailbox::new(Some(self.name.clone()), from_address.clone()))
            .reply_to(Mailbox::new(Some(self.name), self.email))
            .to(to_mailbox.clone())
            .subject("Contact Form Submission")
            .header(ContentType::TEXT_PLAIN)
            .body(self.message)
            .expect("from and to are always set")
    }
}

/// Asks `submitter`'s mail server whether it would accept mail for them, sending
/// `from_address` as the envelope sender.
async fn is_address_deliverable(
    submitter: &Address,
    from_address: &Address,
    hello_name: &str,
) -> Result<bool, SmtpError> {
    let verif_method = VerifMethod::new_with_same_config_for_all(
        None,
        hello_name.to_string(),
        from_address.to_string(),
        lettre::transport::smtp::SMTP_PORT,
        Some(DELIVERABILITY_CHECK_TIMEOUT),
        0,
    );

    let input = CheckEmailInput {
        to_email: submitter.to_string(),
        verif_method,
        ..Default::default()
    };

    Ok(check_email(&input).await.smtp?.is_deliverable)
}

#[derive(Debug, thiserror::Error)]
enum ContactError {
    #[error(transparent)]
    Form(#[from] FormRejection),
    #[error("missing field `{0}`")]
    MissingField(&'static str),
    #[error("invalid email address")]
    InvalidEmail,
    #[error(transparent)]
    Smtp(#[from] lettre::transport::smtp::Error),
    #[error(transparent)]
    SmtpVerification(#[from] SmtpError),
}

impl IntoResponse for ContactError {
    fn into_response(self) -> Response {
        match self {
            Self::Form(rejection) => problem(rejection.status(), rejection.body_text(), None),
            Self::MissingField(field) => problem(
                StatusCode::UNPROCESSABLE_ENTITY,
                format!("The {field} field is required."),
                Some(field),
            ),
            Self::InvalidEmail => problem(
                StatusCode::UNPROCESSABLE_ENTITY,
                "Invalid email address.",
                Some("email"),
            ),
            err @ (Self::Smtp(_) | Self::SmtpVerification(_)) => {
                tracing::error!(error = %err, "failed to process contact form submission");
                problem(
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "The server was unable to complete your request. Please try again later.",
                    None,
                )
            }
        }
    }
}

#[derive(Serialize)]
struct ProblemExt {
    #[serde(skip_serializing_if = "Option::is_none")]
    field: Option<&'static str>,
}

fn problem(
    status: StatusCode,
    detail: impl Into<String>,
    field: Option<&'static str>,
) -> Response {
    ProblemDetails::from_status_code(status)
        .with_detail(detail)
        .with_extensions(ProblemExt { field })
        .into_response()
}
