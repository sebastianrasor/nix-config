use std::net::{IpAddr, Ipv4Addr, SocketAddr};

use figment::{Figment, providers::Env};
use figment_file_provider_adapter::FileAdapter;
use lettre::Address;
use serde::Deserialize;
use url::Url;

const DEFAULT_PORT: u16 = 2002;

const fn default_bind_addr() -> SocketAddr {
    SocketAddr::new(IpAddr::V4(Ipv4Addr::UNSPECIFIED), DEFAULT_PORT)
}

fn default_from_address() -> Address {
    Address::new("noreply", "sebastianrasor.com").expect("valid default from_address")
}

fn default_to_name() -> String {
    "Sebastian Rasor".to_owned()
}

#[derive(Deserialize)]
pub struct EnvConfig {
    #[serde(default = "default_bind_addr")]
    pub bind_addr: SocketAddr,
    pub smtp_connection_url: Url,
    #[serde(default = "default_from_address")]
    pub from_address: Address,
    pub to_address: Address,
    #[serde(default = "default_to_name")]
    pub to_name: String,
    pub turnstile_secret_key: String,
}

impl EnvConfig {
    pub fn from_env() -> Result<Self, Box<figment::Error>> {
        Ok(Figment::new()
            .merge(FileAdapter::wrap(Env::raw()))
            .extract()?)
    }
}
