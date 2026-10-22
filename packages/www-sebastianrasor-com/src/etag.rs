use std::cell::Cell;

use axum::{
    body::Body,
    extract::{Request, State},
    http::{HeaderMap, HeaderValue, Method, StatusCode, header},
    middleware::Next,
    response::Response,
};
use include_dir::{Dir, File};

use crate::include_dir_backend::SERVED_PATH;

pub async fn middleware(
    State(dir): State<&'static Dir<'static>>,
    request: Request,
    next: Next,
) -> Response {
    let method = request.method().clone();
    let request_headers = request.headers().clone();

    let (mut response, served_path) = SERVED_PATH
        .scope(Cell::new(None), async move {
            let response = next.run(request).await;
            (response, SERVED_PATH.with(Cell::get))
        })
        .await;

    if !matches!(
        response.status(),
        StatusCode::OK | StatusCode::PARTIAL_CONTENT
    ) {
        return response;
    }

    let Some(sha256_path) = served_path.map(|path| path.with_added_extension("sha256")) else {
        return response;
    };

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
