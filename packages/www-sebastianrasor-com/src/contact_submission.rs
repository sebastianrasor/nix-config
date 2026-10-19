use crate::app_state::AppState;
use axum::{
    extract::{Form, State},
    http::StatusCode,
    response::{IntoResponse, NoContent, Response},
};
use check_if_email_exists::{
    CheckEmailInput,
    Reachable::{Invalid, Unknown},
    check_email,
};
use lettre::{
    Address, AsyncTransport, Message,
    message::{Mailbox, header::ContentType},
};
use serde::Deserialize;
use thiserror::Error;

const SUBJECT: &str = "Contact Form Submission";

#[derive(Deserialize)]
pub struct ContactSubmission {
    name: String,
    email: Address,
    message: String,
}

impl ContactSubmission {
    fn to_message(
        &self,
        from_address: &Address,
        to_mailbox: &Mailbox,
    ) -> Result<Message, ContactError> {
        let name = self.name.trim();
        let message = self.message.trim();

        if name.is_empty() || message.is_empty() {
            return Err(ContactError::EmptyFields);
        }

        let from = Mailbox::new(Some(name.to_owned()), from_address.clone());
        let reply_to = Mailbox::new(Some(name.to_owned()), self.email.clone());

        Ok(Message::builder()
            .from(from)
            .reply_to(reply_to)
            .to(to_mailbox.clone())
            .subject(SUBJECT)
            .header(ContentType::TEXT_PLAIN)
            .body(message.to_owned())?)
    }
}

#[derive(Error, Debug)]
pub enum ContactError {
    #[error("name or message was empty")]
    EmptyFields,
    #[error("cannot deliver to email")]
    UndeliverableEmail,
    #[error("lettre could not construct a message: {0}")]
    MessageBuild(#[from] lettre::error::Error),
    #[error("lettre could not deliver the message: {0}")]
    SmtpSend(#[from] lettre::transport::smtp::Error),
}

impl IntoResponse for ContactError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            Self::EmptyFields => (
                StatusCode::UNPROCESSABLE_ENTITY,
                "Name and message must not be empty.",
            ),
            Self::UndeliverableEmail => (
                StatusCode::UNPROCESSABLE_ENTITY,
                "Email address is not deliverable.",
            ),
            Self::MessageBuild(_) | Self::SmtpSend(_) => {
                tracing::error!(error = %self, "contact submission error");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "An unexpected error occurred on the server. Please try again later.",
                )
            }
        };

        (status, message).into_response()
    }
}

pub async fn handle(
    State(state): State<AppState>,
    Form(submission): Form<ContactSubmission>,
) -> Result<NoContent, ContactError> {
    let message = submission.to_message(&state.from_address, &state.to_mailbox)?;

    verify_deliverable(&submission.email).await?;

    state.mailer.send(message).await?;

    Ok(NoContent)
}

async fn verify_deliverable(email: &Address) -> Result<(), ContactError> {
    let input = CheckEmailInput {
        to_email: email.to_string(),
        ..Default::default()
    };

    if matches!(check_email(&input).await.is_reachable, Invalid | Unknown) {
        return Err(ContactError::UndeliverableEmail);
    }

    Ok(())
}
