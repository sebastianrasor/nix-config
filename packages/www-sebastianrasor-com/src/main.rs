mod const_assets;
mod contact;

use std::net::{IpAddr, Ipv4Addr, SocketAddr};

use axum::{
    Router,
    http::{StatusCode, header},
    routing::get,
};
use figment::{Figment, providers::Env};
use figment_file_provider_adapter::FileAdapter;
use serde::Deserialize;
use tower_http::trace::TraceLayer;
use tracing::info;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();

    let config = Config::from_env()?;

    let app = Router::new()
        // The site has no favicon. Answering with an empty, long-cached response stops browsers
        // from requesting it on every page load.
        .route(
            "/favicon.ico",
            get(|| async {
                (
                    StatusCode::NO_CONTENT,
                    [(header::CACHE_CONTROL, const_assets::CACHE_CONTROL_IMMUTABLE)],
                )
            }),
        )
        .nest("/api", contact::app(config.contact)?)
        // Static assets are read-only: other methods get `405 Method Not Allowed`.
        .fallback_service(get(const_assets::handler))
        .layer(TraceLayer::new_for_http());

    let listener = tokio::net::TcpListener::bind(config.bind_addr).await?;
    info!("listening on {}", listener.local_addr()?);
    axum::serve(listener, app).await?;

    Ok(())
}

#[derive(Deserialize)]
struct Config {
    #[serde(default = "default_bind_addr")]
    bind_addr: SocketAddr,
    #[serde(flatten)]
    contact: contact::Config,
}

const fn default_bind_addr() -> SocketAddr {
    SocketAddr::new(IpAddr::V4(Ipv4Addr::UNSPECIFIED), 2002)
}

impl Config {
    /// Reads the config from `WWW_`-prefixed environment variables (`WWW_BIND_ADDR` sets
    /// `bind_addr`), where any setting `WWW_KEY` can instead be given as `WWW_KEY_FILE`
    /// naming a file that holds the value.
    ///
    /// The prefix keeps unrelated variables that happen to end in `_FILE` (such as
    /// `SSL_CERT_FILE`) from being treated as settings and read from disk.
    fn from_env() -> Result<Self, Box<figment::Error>> {
        Ok(Figment::new()
            .merge(FileAdapter::wrap(Env::prefixed("WWW_")))
            .extract()?)
    }
}
