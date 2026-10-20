use crate::app_state::AppState;
use crate::env_config::EnvConfig;
use crate::include_dir_backend::IncludeDirBackend;
use axum::{
    Router, middleware,
    response::NoContent,
    routing::{any_service, get, post},
};
use axum_turnstile::TurnstileLayer;
use include_dir::{Dir, include_dir};
use tower_http::{services::ServeDir, trace::TraceLayer};
use tracing_subscriber::EnvFilter;

mod app_state;
mod contact_submission;
mod env_config;
mod include_dir_backend;

const ASSETS_DIR: Dir<'static> = include_dir!("$OUT_DIR/assets");

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| {
            EnvFilter::new("info,tower_http::services::fs::serve_dir::open_file=error")
        }))
        .init();

    let config = EnvConfig::from_env()?;
    let app_state = AppState::try_from(&config)?;
    let turnstile = TurnstileLayer::from_secret(&config.turnstile_secret_key);
    let app = build_router(app_state, turnstile);

    let listener = tokio::net::TcpListener::bind(config.bind_addr).await?;
    tracing::info!("listening on {}", config.bind_addr);
    axum::serve(listener, app).await?;

    Ok(())
}

fn build_router(app_state: AppState, turnstile: TurnstileLayer) -> Router {
    let static_files = any_service(
        ServeDir::with_backend("", IncludeDirBackend::new(&ASSETS_DIR))
            .append_index_html_on_directories(true)
            .html_as_default_extension(true)
            .precompressed_br()
            .precompressed_deflate()
            .precompressed_gzip()
            .precompressed_zstd(),
    )
    .layer(middleware::from_fn(include_dir_backend::etag_middleware));

    // Apply Turnstile before attaching the static-file fallback so that only
    // `POST /contact` requires Turnstile verification, while `GET /contact`
    // falls through to `ServeDir` (serving `assets/contact.html`) instead of
    // returning `405 Method Not Allowed`.
    let contact_route = post(contact_submission::handle)
        .with_state(app_state)
        .layer(turnstile)
        .fallback_service(static_files.clone());

    Router::new()
        .route("/contact", contact_route)
        .route("/favicon.ico", get(|| async { NoContent }))
        .fallback_service(static_files)
        .layer(TraceLayer::new_for_http())
}
