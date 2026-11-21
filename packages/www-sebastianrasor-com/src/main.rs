mod contact;

use std::net::{Ipv4Addr, SocketAddr};

use askama::Template;
use axum::{
    Router,
    body::Bytes,
    http::{HeaderName, HeaderValue, header},
    middleware,
    response::{Html, NoContent, Response},
    routing::get,
};
use memory_serve::CacheControl;
use serviceconf::ServiceConf;
use tokio::signal::unix::{SignalKind, signal};
use tower_http::trace::TraceLayer;
use tracing::{info, level_filters::LevelFilter};
use tracing_subscriber::EnvFilter;

const fn hdr(name: &'static str, value: &'static str) -> (HeaderName, HeaderValue) {
    (
        HeaderName::from_static(name),
        HeaderValue::from_static(value),
    )
}

const SECURITY_HEADERS: [(HeaderName, HeaderValue); 8] = [
    hdr(
        "content-security-policy",
        "default-src 'none'; script-src 'self' 'wasm-unsafe-eval'; worker-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src 'self' blob: data:; font-src 'self'; media-src 'self'; connect-src 'self'; frame-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
    ),
    hdr("x-content-type-options", "nosniff"),
    hdr("x-frame-options", "DENY"),
    hdr("referrer-policy", "no-referrer"),
    hdr("cross-origin-opener-policy", "same-origin"),
    hdr("cross-origin-embedder-policy", "require-corp"),
    hdr("cross-origin-resource-policy", "same-origin"),
    hdr(
        "permissions-policy",
        "camera=(), geolocation=(), microphone=(), payment=(), usb=()",
    ),
];

#[derive(Template)]
#[template(path = "index.html")]
struct IndexTemplate<'a> {
    app_js: &'a str,
    bell: &'a str,
    font: &'a str,
    wasm: &'a str,
    state: Option<&'a str>,
}

#[derive(ServiceConf)]
#[conf(prefix = "WWW_")]
struct Config {
    #[conf(default = SocketAddr::from((Ipv4Addr::LOCALHOST, 2002)))]
    bind_addr: SocketAddr,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::builder()
                .with_default_directive(LevelFilter::INFO.into())
                .from_env_lossy(),
        )
        .init();

    let config = Config::from_env()?;
    let contact_config = contact::Config::from_env()?;

    let app = build_app(contact_config)?.layer(TraceLayer::new_for_http());

    let listener = tokio::net::TcpListener::bind(config.bind_addr).await?;
    info!("listening on {}", listener.local_addr()?);
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .with_graceful_shutdown(shutdown_signal())
    .await?;

    Ok(())
}

fn build_app(contact_config: contact::Config) -> Result<Router, Box<dyn std::error::Error>> {
    let assets = memory_serve::load!()
        .index_file(None)
        .enable_hashed_routes(true)
        .cache_control(CacheControl::Short);
    let manifest = assets.manifest();

    let asset_url = |route: &'static str| manifest.get(route).unwrap_or(route);
    let index_html = Bytes::from(
        IndexTemplate {
            app_js: asset_url("/app.js"),
            bell: asset_url("/bell.ogg"),
            font: asset_url("/AtkinsonHyperlegibleMono.woff2"),
            wasm: asset_url("/v86.wasm"),
            state: manifest.get("/state.zst"),
        }
        .render()?,
    );

    let serve_spa = get(async move || {
        (
            [(header::CACHE_CONTROL, HeaderValue::from_static("no-cache"))],
            Html(index_html),
        )
    });

    Ok(Router::new()
        .route("/favicon.ico", get(async || NoContent))
        .nest("/api", contact::app(contact_config)?)
        .merge(assets.into_router())
        .fallback(serve_spa)
        .layer(middleware::map_response(async |res: Response| {
            (SECURITY_HEADERS, res)
        })))
}

async fn shutdown_signal() {
    let mut sigterm = signal(SignalKind::terminate()).expect("SIGTERM handler is installable");
    tokio::select! {
        _ = tokio::signal::ctrl_c() => {}
        _ = sigterm.recv() => {}
    }
    info!("received shutdown signal, draining in-flight requests");
}

#[cfg(test)]
mod tests {
    use axum::http::StatusCode;
    use axum_test::TestServer;

    use super::*;

    #[tokio::test]
    async fn serves_spa_routes_and_cache_busted_assets() {
        let server = TestServer::new(build_app(contact::Config::default()).unwrap());

        server
            .get("/favicon.ico")
            .await
            .assert_status(StatusCode::NO_CONTENT);

        for route in ["/", "/contact", "/targets", "/linux-intro"] {
            let resp = server.get(route).await;
            resp.assert_status_ok();
            assert!(resp.headers().contains_key(header::CONTENT_SECURITY_POLICY));
            resp.assert_header("cross-origin-opener-policy", "same-origin");
            resp.assert_header("cross-origin-embedder-policy", "require-corp");
            resp.assert_text_contains("<title>Sebastian Rasor</title>");
            resp.assert_text_contains(r#"<div id="terminal""#);
        }

        let index_body = server.get("/").await.text();
        let (_, rest) = index_body
            .split_once(r#"<script type="module" src=""#)
            .unwrap();
        let (hashed_app_js, _) = rest.split_once('"').unwrap();

        assert!(
            hashed_app_js
                .strip_prefix("/app.")
                .and_then(|s| s.strip_suffix(".js"))
                .is_some_and(|h| h.len() == 16 && h.chars().all(|c| c.is_ascii_hexdigit()))
        );
        server.get(hashed_app_js).await.assert_status_ok();

        let sitemap = server.get("/sitemap.xml").await;
        sitemap.assert_status_ok();
        sitemap.assert_text_contains("<loc>https://www.sebastianrasor.com/</loc>");
        sitemap.assert_text_contains("<loc>https://www.sebastianrasor.com/contact</loc>");
        sitemap.assert_text_contains("<loc>https://www.sebastianrasor.com/targets</loc>");

        let robots = server.get("/robots.txt").await;
        robots.assert_status_ok();
        robots.assert_text_contains("Sitemap: https://www.sebastianrasor.com/sitemap.xml");

        #[cfg(not(debug_assertions))]
        {
            let br_resp = server
                .get(hashed_app_js)
                .add_header(header::ACCEPT_ENCODING, "br")
                .await;
            br_resp.assert_status_ok();
            br_resp.assert_header(header::CONTENT_ENCODING, "br");
            br_resp.assert_header(header::CACHE_CONTROL, "max-age=31536000, immutable");

            let pdf_resp = server.get("/targets/4x6-6x-usbr.pdf").await;
            pdf_resp.assert_status_ok();
            pdf_resp.assert_header(header::CONTENT_TYPE, "application/pdf");
        }
    }
}
