use std::{ffi::OsString, time::Duration};

use axum::{
    Router,
    extract::{Form, State},
    http::StatusCode,
    response::{IntoResponse, NoContent, Response},
    routing::post,
};
use axum_turnstile::TurnstileLayer;
use check_if_email_exists::{CheckEmailInput, check_email, smtp::verif_method::VerifMethod};
use lettre::{
    Address, AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor,
    message::{Mailbox, header::ContentType},
};
use serde::Deserialize;
use serde_inline_default::serde_inline_default;
use thiserror::Error;
use tracing::{debug, error, info, instrument, warn};

const DEFAULT_FROM_ADDRESS: &str = "noreply@sebastianrasor.com";

#[serde_inline_default]
#[derive(Clone, Deserialize)]
pub struct Config {
    #[serde_inline_default(DEFAULT_FROM_ADDRESS.parse::<>().expect("valid default from_address"))]
    from_address: Address,
    smtp_connection_url: String,
    to_mailbox: Mailbox,
    turnstile_secret_key: String,
}

#[derive(Clone)]
struct AppState {
    from_address: Address,
    to_mailbox: Mailbox,
    sender: AsyncSmtpTransport<Tokio1Executor>,
}

#[derive(Deserialize)]
struct Submission {
    message: String,
    #[serde(rename = "email")]
    email_address: Address,
    name: String,
}

impl Submission {
    fn to_from_mailbox(&self, from_address: &Address) -> Mailbox {
        Mailbox::new(Some(self.name.clone()), from_address.clone())
    }

    fn to_reply_to_mailbox(&self) -> Mailbox {
        Mailbox::new(Some(self.name.clone()), self.email_address.clone())
    }

    fn to_message(
        &self,
        from_address: &Address,
        to_mailbox: &Mailbox,
    ) -> Result<Message, lettre::error::Error> {
        Message::builder()
            .from(self.to_from_mailbox(from_address))
            .reply_to(self.to_reply_to_mailbox())
            .to(to_mailbox.clone())
            .subject("Contact Form Submission")
            .header(ContentType::TEXT_PLAIN)
            .body(self.message.clone())
    }
}

#[derive(Error, Debug)]
enum ContactError {
    #[error("cannot deliver to email")]
    EmailAddressNotDeliverable,
    #[error("failed to build email message: {0}")]
    BuildMessage(#[from] lettre::error::Error),
    #[error("failed to send email over SMTP: {0}")]
    SendEmail(#[from] lettre::transport::smtp::Error),
}

impl IntoResponse for ContactError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            Self::EmailAddressNotDeliverable => {
                debug!("{self}");
                (
                    StatusCode::UNPROCESSABLE_ENTITY,
                    "Email address is not deliverable.",
                )
            }
            Self::BuildMessage(_) | Self::SendEmail(_) => {
                error!("{self}");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "The server was unable to complete your request. Please try again later.",
                )
            }
        };

        (status, message).into_response()
    }
}

pub fn app(config: Config) -> Result<Router, Box<dyn std::error::Error>> {
    let sender =
        AsyncSmtpTransport::<Tokio1Executor>::from_url(&config.smtp_connection_url)?.build();

    let turnstile = TurnstileLayer::from_secret(&config.turnstile_secret_key);
    let state = AppState {
        from_address: config.from_address,
        to_mailbox: config.to_mailbox,
        sender,
    };

    Ok(Router::new().route("/contact", post(handler).with_state(state).layer(turnstile)))
}

#[instrument(
    skip_all,
    fields(
        name = %submission.name,
        email_address = %submission.email_address,
    ),
)]
async fn handler(
    State(state): State<AppState>,
    Form(submission): Form<Submission>,
) -> Result<NoContent, ContactError> {
    let message = submission.to_message(&state.from_address, &state.to_mailbox)?;

    if !is_address_deliverable(&submission.email_address, &state.from_address).await {
        return Err(ContactError::EmailAddressNotDeliverable);
    }

    state.sender.send(message).await?;
    info!("contact form submission sent");

    Ok(NoContent)
}

async fn is_address_deliverable(to_address: &Address, from_address: &Address) -> bool {
    let Ok(Ok(hostname)) = hostname::get().map(OsString::into_string) else {
        return false;
    };

    let verif_method = VerifMethod::new_with_same_config_for_all(
        None,
        hostname,
        from_address.to_string(),
        lettre::transport::smtp::SMTP_PORT,
        Some(Duration::from_secs(10)),
        0,
    );

    let input = CheckEmailInput {
        to_email: to_address.to_string(),
        verif_method,
        ..Default::default()
    };

    match check_email(&input).await.smtp {
        Ok(smtp_details) => {
            debug!(
                is_deliverable = smtp_details.is_deliverable,
                "checked email address deliverability"
            );
            smtp_details.is_deliverable
        }
        Err(err) => {
            warn!(error = %err, "failed to check email address deliverability");
            false
        }
    }
}
