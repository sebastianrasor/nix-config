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

#[derive(Deserialize)]
#[cfg_attr(debug_assertions, serde(default))]
pub struct Config {
    #[serde(default = "default_from_address")]
    from_address: Address,
    smtp_connection_url: String,
    to_mailbox: Mailbox,
    turnstile_secret_key: String,
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
            turnstile_secret_key: "1x0000000000000000000000000000000AA".to_string(),
        }
    }
}

struct AppState {
    from_address: Address,
    to_mailbox: Mailbox,
    verif_method: VerifMethod,
    sender: AsyncSmtpTransport<Tokio1Executor>,
}

#[derive(Deserialize)]
struct Submission {
    name: Option<String>,
    email: Option<String>,
    message: Option<String>,
}

#[derive(Debug, thiserror::Error)]
enum ContactError {
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
    let turnstile = TurnstileLayer::from_secret(&config.turnstile_secret_key);
    let state = Arc::new(AppState {
        from_address: config.from_address,
        to_mailbox: config.to_mailbox,
        verif_method,
        sender,
    });

    Ok(Router::new().route("/contact", post(handler).with_state(state).layer(turnstile)))
}

async fn handler(
    State(state): State<Arc<AppState>>,
    form: Result<Form<Submission>, FormRejection>,
) -> Result<NoContent, ContactError> {
    let Form(submission) = form?;
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

fn required(value: Option<String>, field: &'static str) -> Result<String, ContactError> {
    value
        .filter(|value| !value.trim().is_empty())
        .ok_or(ContactError::MissingField(field))
}
