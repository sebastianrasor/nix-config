use axum::{
    extract::{Request, State},
    http::{HeaderName, HeaderValue, StatusCode, header},
    middleware::Next,
    response::{IntoResponse, Response},
};
use include_dir::{Dir, File};

use crate::include_dir_backend::with_served_path;

pub async fn middleware(
    State(dir): State<&'static Dir<'static>>,
    request: Request,
    next: Next,
) -> Response {
    let (mut response, served_path) = with_served_path(next.run(request)).await;

    let Some(served_path) = served_path else {
        return response;
    };

    if served_path.extension().is_some_and(|ext| ext == "headers") {
        return StatusCode::NOT_FOUND.into_response();
    }

    if !matches!(
        response.status(),
        StatusCode::OK | StatusCode::PARTIAL_CONTENT
    ) {
        return response;
    }

    let headers_path = if response.headers().contains_key(header::CONTENT_ENCODING) {
        served_path.with_extension("headers")
    } else {
        served_path.with_added_extension("headers")
    };

    let Some(headers) = dir.get_file(headers_path).and_then(File::contents_utf8) else {
        return response;
    };

    for (name, value) in headers.lines().filter_map(|line| line.split_once(':')) {
        let Ok(name) = HeaderName::from_bytes(name.trim().as_bytes()) else {
            continue;
        };
        let Ok(value) = HeaderValue::from_str(value.trim()) else {
            continue;
        };

        response.headers_mut().append(name, value);
    }

    response
}
