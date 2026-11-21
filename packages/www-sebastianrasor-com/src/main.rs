mod const_assets;
mod contact;

use std::net::{IpAddr, Ipv4Addr, SocketAddr};

use axum::{
    Router,
    http::{HeaderName, HeaderValue, header},
};
use figment::{Figment, providers::Env};
use figment_file_provider_adapter::FileAdapter;
use serde::Deserialize;
use tower_http::{set_header::SetResponseHeaderLayer, trace::TraceLayer};
use tracing::info;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();

    let config: Config = Figment::new()
        .merge(FileAdapter::wrap(Env::prefixed("WWW_")))
        .extract()?;

    let app = Router::new()
        .nest("/api", contact::app(config.contact))
        .fallback_service(const_assets::app())
        .layer(SetResponseHeaderLayer::overriding(
            header::X_CONTENT_TYPE_OPTIONS,
            HeaderValue::from_static("nosniff"),
        ))
        .layer(SetResponseHeaderLayer::overriding(
            header::X_FRAME_OPTIONS,
            HeaderValue::from_static("DENY"),
        ))
        .layer(SetResponseHeaderLayer::overriding(
            header::REFERRER_POLICY,
            HeaderValue::from_static("no-referrer"),
        ))
        .layer(SetResponseHeaderLayer::overriding(
            HeaderName::from_static("permissions-policy"),
            HeaderValue::from_static(
                "camera=(), geolocation=(), microphone=(), payment=(), usb=()",
            ),
        ))
        .layer(TraceLayer::new_for_http());

    let listener = tokio::net::TcpListener::bind(config.bind_addr).await?;
    info!("listening on {}", listener.local_addr()?);
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await?;

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
    SocketAddr::new(IpAddr::V4(Ipv4Addr::LOCALHOST), 2002)
}
