use std::iter;

use axum::{
    Router,
    http::{StatusCode, Uri, header},
    response::{AppendHeaders, IntoResponse, Response},
    routing::get,
};
use axum_extra::{extract::TypedHeader, headers::IfNoneMatch};
use http_encoding_headers::{AcceptEncoding, Encoding};

include!(concat!(env!("OUT_DIR"), "/asset_table.rs"));

const CACHE_CONTROL_IMMUTABLE: &str = "public, max-age=31536000, immutable";
const CACHE_CONTROL_NO_STORE: &str = "no-store, no-cache, must-revalidate";
const CACHE_CONTROL_REVALIDATE: &str = "max-age=300, must-revalidate";

struct EncodedAsset {
    encoding: Encoding,
    etag: &'static str,
    data: &'static [u8],
}

struct ConstAsset {
    content_type: &'static str,
    identity: EncodedAsset,
    compressed: &'static [EncodedAsset],
    headers: &'static [(&'static str, &'static str)],
}

impl ConstAsset {
    fn variants(&self) -> impl Iterator<Item = &EncodedAsset> {
        iter::once(&self.identity).chain(self.compressed)
    }
}

pub fn app() -> Router {
    Router::new()
        .route(
            "/favicon.ico",
            get(|| async {
                (
                    StatusCode::NO_CONTENT,
                    [(header::CACHE_CONTROL, CACHE_CONTROL_IMMUTABLE)],
                )
            }),
        )
        .fallback_service(get(handler))
}

async fn handler(
    accept_encoding: Option<TypedHeader<AcceptEncoding>>,
    if_none_match: Option<TypedHeader<IfNoneMatch>>,
    uri: Uri,
) -> Response {
    let path = uri.path();

    if let Some(trimmed) = path.strip_suffix('/').filter(|trimmed| !trimmed.is_empty())
        && ASSET_MAP.contains_key(trimmed)
    {
        let location = uri
            .query()
            .map_or_else(|| trimmed.to_owned(), |query| format!("{trimmed}?{query}"));
        return (
            StatusCode::PERMANENT_REDIRECT,
            [
                (header::LOCATION, location.as_str()),
                (header::CACHE_CONTROL, CACHE_CONTROL_REVALIDATE),
            ],
        )
            .into_response();
    }

    let Some(asset) = ASSET_MAP.get(path) else {
        return (
            StatusCode::NOT_FOUND,
            [(header::CACHE_CONTROL, CACHE_CONTROL_NO_STORE)],
        )
            .into_response();
    };

    let offered = asset.variants().map(|variant| &variant.encoding);
    let variant = accept_encoding
        .as_deref()
        .and_then(|accept_encoding| accept_encoding.preferred_allowed(offered))
        .and_then(|wanted| asset.variants().find(|variant| &variant.encoding == wanted))
        .unwrap_or(&asset.identity);

    let cache_control = if path.starts_with(DIGEST_PREFIX) {
        CACHE_CONTROL_IMMUTABLE
    } else {
        CACHE_CONTROL_REVALIDATE
    };
    let headers = (
        [
            (header::VARY, "Accept-Encoding"),
            (header::ETAG, variant.etag),
            (header::CACHE_CONTROL, cache_control),
        ],
        AppendHeaders(asset.headers.iter().copied()),
    );

    if let Some(TypedHeader(if_none_match)) = if_none_match
        && let Ok(etag) = variant.etag.parse()
        && !if_none_match.precondition_passes(&etag)
    {
        return (StatusCode::NOT_MODIFIED, headers).into_response();
    }

    let content_encoding = (variant.encoding != Encoding::Identity)
        .then(|| [(header::CONTENT_ENCODING, variant.encoding.to_string())]);

    (
        headers,
        [(header::CONTENT_TYPE, asset.content_type)],
        content_encoding,
        variant.data,
    )
        .into_response()
}

#[cfg(test)]
mod tests {
    use axum::body::to_bytes;

    use super::*;

    async fn get_uri(uri: &str) -> (StatusCode, axum::http::HeaderMap, String) {
        let response = handler(None, None, uri.parse().unwrap()).await;
        let status = response.status();
        let headers = response.headers().clone();
        let bytes = to_bytes(response.into_body(), usize::MAX).await.unwrap();
        (
            status,
            headers,
            String::from_utf8_lossy(&bytes).into_owned(),
        )
    }

    #[tokio::test]
    async fn serves_home_routes_and_readme_aliases() {
        let (status, root_headers, root_body) = get_uri("/").await;
        assert_eq!(status, StatusCode::OK);
        assert!(root_body.contains(r#"data-initial-command="cat README""#));
        assert!(root_body.contains("data-home-fs="));
        assert!(root_body.contains(r#"href="https://www.sebastianrasor.com/""#));

        let (alias_status, alias_headers, _) = get_uri("/README").await;
        assert_eq!(alias_status, StatusCode::OK);
        assert_eq!(
            root_headers.get(header::ETAG),
            alias_headers.get(header::ETAG)
        );

        let (status, contact_headers, contact_body) = get_uri("/contact").await;
        assert_eq!(status, StatusCode::OK);
        assert!(contact_body.contains(r#"data-initial-command="cat contact/README""#));
        assert!(contact_body.contains(r#"href="https://www.sebastianrasor.com/contact""#));

        let (alias_status, contact_alias_headers, _) = get_uri("/contact/README").await;
        assert_eq!(alias_status, StatusCode::OK);
        assert_eq!(
            contact_headers.get(header::ETAG),
            contact_alias_headers.get(header::ETAG)
        );

        let (status, _, eml_body) = get_uri("/contact/message.eml").await;
        assert_eq!(status, StatusCode::OK);
        assert!(eml_body.contains(r#"data-initial-command="cat contact/message.eml""#));

        let (status, _, targets_body) = get_uri("/targets").await;
        assert_eq!(status, StatusCode::OK);
        assert!(targets_body.contains(r#"data-initial-command="cat targets/README""#));
    }

    #[tokio::test]
    async fn redirects_trailing_slashes_and_preserves_404s() {
        let (status, headers, _) = get_uri("/contact/").await;
        assert_eq!(status, StatusCode::PERMANENT_REDIRECT);
        assert_eq!(headers.get(header::LOCATION).unwrap(), "/contact");

        let (status, headers, _) = get_uri("/targets/?foo=bar").await;
        assert_eq!(status, StatusCode::PERMANENT_REDIRECT);
        assert_eq!(headers.get(header::LOCATION).unwrap(), "/targets?foo=bar");

        let (status, _, _) = get_uri("/nonexistent/").await;
        assert_eq!(status, StatusCode::NOT_FOUND);
    }

    #[tokio::test]
    async fn serves_generated_sitemap_and_target_pdfs() {
        let (status, _, sitemap) = get_uri("/sitemap.xml").await;
        assert_eq!(status, StatusCode::OK);
        assert!(sitemap.contains("<loc>https://www.sebastianrasor.com/</loc>"));
        assert!(sitemap.contains("<loc>https://www.sebastianrasor.com/contact</loc>"));
        assert!(sitemap.contains("<loc>https://www.sebastianrasor.com/targets</loc>"));

        if ASSET_MAP.contains_key("/targets/4x6-6x-usbr.pdf") {
            let response = handler(None, None, "/targets/4x6-6x-usbr.pdf".parse().unwrap()).await;
            assert_eq!(response.status(), StatusCode::OK);
            assert_eq!(
                response.headers().get(header::CONTENT_TYPE).unwrap(),
                "application/pdf"
            );
        }
    }
}
