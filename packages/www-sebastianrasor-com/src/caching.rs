use axum::{
    body::Body,
    extract::{Query, Request, State},
    http::{HeaderMap, HeaderValue, Method, StatusCode, header},
    middleware::Next,
    response::{IntoResponse, Response},
};
use include_dir::{Dir, File};
use serde::Deserialize;

use crate::include_dir_backend::with_served_path;

#[derive(Deserialize)]
pub struct QueryParams {
    v: Option<String>,
}

pub async fn middleware(
    State(dir): State<&'static Dir<'static>>,
    Query(QueryParams { v }): Query<QueryParams>,
    request: Request,
    next: Next,
) -> Response {
    let method = request.method().clone();
    let request_headers = request.headers().clone();

    let (mut response, served_path) = with_served_path(next.run(request)).await;

    if !matches!(
        response.status(),
        StatusCode::OK | StatusCode::PARTIAL_CONTENT
    ) {
        return response;
    }

    let Some(served_path) = served_path else {
        return response;
    };

    let asset_sha256_path = if response.headers().contains_key(header::CONTENT_ENCODING) {
        served_path.with_extension("sha256")
    } else {
        served_path.with_added_extension("sha256")
    };

    let Some(asset_hash) = dir
        .get_file(asset_sha256_path)
        .and_then(File::contents_utf8)
    else {
        return response;
    };

    let cache_control = match v.as_deref() {
        None => HeaderValue::from_static("public, no-cache"),
        Some(version) if version == asset_hash => {
            HeaderValue::from_static("public, max-age=31536000, immutable")
        }
        Some(_) => {
            return (
                StatusCode::NOT_FOUND,
                [(header::CACHE_CONTROL, HeaderValue::from_static("no-store"))],
            )
                .into_response();
        }
    };

    response
        .headers_mut()
        .insert(header::CACHE_CONTROL, cache_control);

    let sha256_path = served_path.with_added_extension("sha256");
    let Some(hash) = dir.get_file(sha256_path).and_then(File::contents_utf8) else {
        return response;
    };

    let etag = format!("\"{hash}\"");
    let Ok(etag_header) = HeaderValue::from_str(&etag) else {
        return response;
    };

    if matches!(method, Method::GET | Method::HEAD)
        && if_none_match_matches(&request_headers, &etag)
    {
        *response.status_mut() = StatusCode::NOT_MODIFIED;
        response.headers_mut().remove(header::ACCEPT_RANGES);
        response.headers_mut().remove(header::CONTENT_ENCODING);
        response.headers_mut().remove(header::CONTENT_LENGTH);
        response.headers_mut().remove(header::CONTENT_RANGE);
        response.headers_mut().remove(header::CONTENT_TYPE);
        *response.body_mut() = Body::empty();
    }

    response.headers_mut().insert(header::ETAG, etag_header);

    response
}

fn if_none_match_matches(headers: &HeaderMap, etag: &str) -> bool {
    headers
        .get_all(header::IF_NONE_MATCH)
        .iter()
        .filter_map(|value| value.to_str().ok())
        .flat_map(|value| value.split(','))
        .map(str::trim)
        .any(|tag| tag == "*" || tag.strip_prefix("W/").unwrap_or(tag) == etag)
}
