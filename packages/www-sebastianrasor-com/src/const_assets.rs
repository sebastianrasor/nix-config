use std::iter;

use axum::{
    Router,
    http::{StatusCode, Uri, header},
    response::{IntoResponse, Response},
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
    let headers = [
        (header::VARY, "Accept-Encoding"),
        (header::ETAG, variant.etag),
        (header::CACHE_CONTROL, cache_control),
    ];

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
