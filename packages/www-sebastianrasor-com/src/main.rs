use std::net::{Ipv4Addr, SocketAddr};

use crate::include_dir_backend::IncludeDirBackend;
use axum::{Router, middleware, response::NoContent, routing::get};
use figment::{Figment, providers::Env};
use figment_file_provider_adapter::FileAdapter;
use include_dir::{Dir, include_dir};
use serde::Deserialize;
use tower_http::{services::ServeDir, trace::TraceLayer};
use tracing::info;

mod contact;
mod etag;
mod include_dir_backend;

const DEFAULT_PORT: u16 = 2002;

static ASSETS_DIR: Dir<'_> = include_dir!("$OUT_DIR/assets");

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();

    let config = Config::from_env()?;

    let api_routes = Router::new().merge(contact::app(config.contact)?);

    let assets_service = ServeDir::with_backend("", IncludeDirBackend::from(&ASSETS_DIR))
        .append_index_html_on_directories(true)
        .html_as_default_extension(true)
        .precompressed_br()
        .precompressed_deflate()
        .precompressed_gzip()
        .precompressed_zstd();

    let app = Router::new()
        .nest("/api", api_routes)
        .route("/favicon.ico", get(|| async { NoContent }))
        .fallback_service(assets_service)
        .layer(middleware::from_fn_with_state(
            &ASSETS_DIR,
            etag::middleware,
        ))
        .layer(TraceLayer::new_for_http());

    let listener = tokio::net::TcpListener::bind(config.bind_addr).await?;
    info!("listening on {}", listener.local_addr()?);
    axum::serve(listener, app).await?;

    Ok(())
}

const fn default_bind_addr() -> SocketAddr {
    SocketAddr::new(std::net::IpAddr::V4(Ipv4Addr::UNSPECIFIED), DEFAULT_PORT)
}

#[derive(Clone, Deserialize)]
struct Config {
    #[serde(default = "default_bind_addr")]
    bind_addr: SocketAddr,
    #[serde(flatten)]
    contact: contact::Config,
}

impl Config {
    fn from_env() -> Result<Self, Box<figment::Error>> {
        Ok(Figment::new()
            .merge(FileAdapter::wrap(Env::raw()))
            .extract()?)
    }
}
