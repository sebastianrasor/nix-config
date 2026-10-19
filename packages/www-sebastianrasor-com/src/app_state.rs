use crate::env_config::EnvConfig;
use lettre::{Address, AsyncSmtpTransport, Tokio1Executor, message::Mailbox};

#[derive(Clone)]
pub struct AppState {
    pub from_address: Address,
    pub to_mailbox: Mailbox,
    pub mailer: AsyncSmtpTransport<Tokio1Executor>,
}

impl TryFrom<&EnvConfig> for AppState {
    type Error = lettre::transport::smtp::Error;

    fn try_from(config: &EnvConfig) -> Result<Self, Self::Error> {
        let mailer =
            AsyncSmtpTransport::<Tokio1Executor>::from_url(config.smtp_connection_url.as_str())?
                .build();

        Ok(Self {
            from_address: config.from_address.clone(),
            to_mailbox: Mailbox::new(Some(config.to_name.clone()), config.to_address.clone()),
            mailer,
        })
    }
}
