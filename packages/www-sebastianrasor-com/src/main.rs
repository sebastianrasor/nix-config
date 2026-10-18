use std::{env, path::PathBuf, sync::Arc};

use axum::{
    Router,
    extract::{Form, State},
    http::StatusCode,
    response::{IntoResponse, NoContent, Response},
    routing::{get, post},
};
use axum_turnstile::TurnstileLayer;
use check_if_email_exists::{
    CheckEmailInputBuilder,
    Reachable::{Invalid, Unknown},
    check_email,
};
use lettre::{
    Address, AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor,
    message::{Mailbox, header::ContentType},
    transport::smtp::authentication::Credentials,
};
use serde::Deserialize;
use tower_http::services::{ServeDir, ServeFile};

const FROM_DOMAIN: &str = "sebastianrasor.com";
const FROM_USER: &str = "noreply";
const SUBJECT: &str = "Contact Form Submission";
const TO_NAME: &str = "Sebastian Rasor";

#[derive(Deserialize)]
struct EnvConfig {
    smtp_relay: String,
    smtp_username: String,
    smtp_password: String,
    to_user: String,
    to_domain: String,
    turnstile_secret_key: String,
}

struct AppState {
    from_address: Address,
    to_mailbox: Mailbox,
    mailer: AsyncSmtpTransport<Tokio1Executor>,
}

impl AppState {
    fn from_config(config: &EnvConfig) -> Result<Self, Box<dyn std::error::Error>> {
        let credentials =
            Credentials::new(config.smtp_username.clone(), config.smtp_password.clone());

        let mailer = AsyncSmtpTransport::<Tokio1Executor>::relay(&config.smtp_relay)?
            .credentials(credentials)
            .build();

        let to_address = Address::new(config.to_user.clone(), config.to_domain.clone())?;

        Ok(Self {
            from_address: Address::new_dangerous(FROM_USER, FROM_DOMAIN),
            to_mailbox: Mailbox::new(Some(TO_NAME.to_owned()), to_address),
            mailer,
        })
    }
}

#[derive(Deserialize)]
struct ContactSubmission {
    name: String,
    email: String,
    message: String,
}

impl ContactSubmission {
    fn into_message(
        self,
        reply_to: Address,
        from_address: Address,
        to_mailbox: Mailbox,
    ) -> Result<Message, ContactError> {
        Message::builder()
            .from(Mailbox::new(Some(self.name.clone()), from_address))
            .reply_to(Mailbox::new(Some(self.name), reply_to))
            .to(to_mailbox)
            .subject(SUBJECT)
            .header(ContentType::TEXT_PLAIN)
            .body(self.message)
            .map_err(|_| ContactError::BuildEmail)
    }
}

enum ContactError {
    InvalidEmailAddress,
    BuildVerifierInput,
    UndeliverableEmail,
    BuildEmail,
    SendEmail,
}

impl IntoResponse for ContactError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            Self::InvalidEmailAddress => (
                StatusCode::UNPROCESSABLE_ENTITY,
                "Could not construct reply-to address.",
            ),
            Self::UndeliverableEmail => (
                StatusCode::UNPROCESSABLE_ENTITY,
                "Email address is not deliverable.",
            ),
            Self::BuildVerifierInput => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Could not construct CheckEmailInputBuilder.",
            ),
            Self::BuildEmail => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Could not construct email.",
            ),
            Self::SendEmail => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Failed to deliver email.",
            ),
        };

        (status, message).into_response()
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = envy::from_env::<EnvConfig>()?;
    let app_state = Arc::new(AppState::from_config(&config)?);
    let turnstile = TurnstileLayer::from_secret(config.turnstile_secret_key);
    let assets_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("assets");

    let contact_route = post(contact_submission)
        .with_state(app_state)
        .layer(turnstile)
        .get_service(ServeFile::new(assets_dir.join("contact.html")));

    let static_files = ServeDir::new(&assets_dir)
        .append_index_html_on_directories(true)
        .html_as_default_extension(true);

    let app = Router::new()
        .route("/contact", contact_route)
        .route("/favicon.ico", get(|| async { NoContent }))
        .fallback_service(static_files);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:2002").await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn contact_submission(
    State(state): State<Arc<AppState>>,
    Form(submission): Form<ContactSubmission>,
) -> Result<NoContent, ContactError> {
    let reply_to = submission
        .email
        .parse::<Address>()
        .map_err(|_| ContactError::InvalidEmailAddress)?;

    verify_deliverable(&submission.email).await?;

    let email = submission.into_message(
        reply_to,
        state.from_address.clone(),
        state.to_mailbox.clone(),
    )?;

    state
        .mailer
        .send(email)
        .await
        .map_err(|_| ContactError::SendEmail)?;

    Ok(NoContent)
}

async fn verify_deliverable(email: &str) -> Result<(), ContactError> {
    let input = CheckEmailInputBuilder::default()
        .to_email(email.to_owned())
        .build()
        .map_err(|_| ContactError::BuildVerifierInput)?;

    if matches!(check_email(&input).await.is_reachable, Invalid | Unknown) {
        return Err(ContactError::UndeliverableEmail);
    }

    Ok(())
}
