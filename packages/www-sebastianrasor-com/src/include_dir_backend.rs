use std::{
    cell::Cell,
    collections::HashMap,
    fmt::Write as _,
    future::{Ready, ready},
    io::{self, Cursor, SeekFrom},
    path::{Path, PathBuf},
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
    time::SystemTime,
};

use axum::{
    extract::Request,
    http::{HeaderValue, StatusCode, header},
    middleware::Next,
    response::{IntoResponse, Response},
};
use include_dir::Dir;
use sha2::{Digest, Sha256};
use tokio::io::{AsyncRead, AsyncSeek, ReadBuf};
use tower_http::services::fs::{Backend, File, Metadata};

tokio::task_local! {
    static SERVED_ETAG: Cell<Option<HeaderValue>>;
}

fn record_served_etag(etag: &HeaderValue) {
    let _ = SERVED_ETAG.try_with(|slot| slot.set(Some(etag.clone())));
}

#[derive(Debug, Clone)]
enum EmbeddedEntry {
    Dir,
    File(EmbeddedFile),
}

/// A `tower_http::services::fs::Backend` backed by an `include_dir::Dir`.
#[derive(Debug, Clone)]
pub struct IncludeDirBackend {
    entries: Arc<HashMap<&'static Path, EmbeddedEntry>>,
}

impl IncludeDirBackend {
    pub fn new(dir: &'static Dir<'static>) -> Self {
        let mut entries = HashMap::from([(Path::new(""), EmbeddedEntry::Dir)]);
        collect_entries(dir, &mut entries);

        Self {
            entries: Arc::new(entries),
        }
    }
}

impl Backend for IncludeDirBackend {
    type File = EmbeddedFile;
    type Metadata = EmbeddedMetadata;
    type OpenFuture = Ready<io::Result<Self::File>>;
    type MetadataFuture = Ready<io::Result<Self::Metadata>>;

    fn open(&self, path: PathBuf) -> Self::OpenFuture {
        let result = match self.entries.get(normalize_path(&path)) {
            Some(EmbeddedEntry::File(file)) => {
                record_served_etag(&file.etag);
                Ok(file.clone())
            }
            Some(EmbeddedEntry::Dir) | None => Err(io::Error::from(io::ErrorKind::NotFound)),
        };

        ready(result)
    }

    fn metadata(&self, path: PathBuf) -> Self::MetadataFuture {
        let result = match self.entries.get(normalize_path(&path)) {
            Some(EmbeddedEntry::Dir) => Ok(EmbeddedMetadata::Dir),
            Some(EmbeddedEntry::File(file)) => {
                record_served_etag(&file.etag);
                Ok(file.metadata)
            }
            None => Err(io::Error::from(io::ErrorKind::NotFound)),
        };

        ready(result)
    }
}

/// An in-memory file supporting `AsyncRead` and `AsyncSeek` via `std::io::Cursor`.
#[derive(Debug, Clone)]
pub struct EmbeddedFile {
    cursor: Cursor<&'static [u8]>,
    metadata: EmbeddedMetadata,
    etag: HeaderValue,
}

impl EmbeddedFile {
    fn new(file: &'static include_dir::File<'static>) -> Self {
        let contents = file.contents();
        Self {
            cursor: Cursor::new(contents),
            metadata: EmbeddedMetadata::File {
                len: contents.len() as u64,
            },
            etag: compute_etag(contents),
        }
    }
}

impl AsyncRead for EmbeddedFile {
    fn poll_read(
        mut self: Pin<&mut Self>,
        cx: &mut Context<'_>,
        buf: &mut ReadBuf<'_>,
    ) -> Poll<io::Result<()>> {
        Pin::new(&mut self.cursor).poll_read(cx, buf)
    }
}

impl AsyncSeek for EmbeddedFile {
    fn start_seek(mut self: Pin<&mut Self>, position: SeekFrom) -> io::Result<()> {
        Pin::new(&mut self.cursor).start_seek(position)
    }

    fn poll_complete(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<io::Result<u64>> {
        Pin::new(&mut self.cursor).poll_complete(cx)
    }
}

impl File for EmbeddedFile {
    type Metadata = EmbeddedMetadata;
    type MetadataFuture<'a> = Ready<io::Result<Self::Metadata>>;

    fn metadata(&self) -> Self::MetadataFuture<'_> {
        ready(Ok(self.metadata))
    }
}

/// Metadata for an embedded file or directory.
#[derive(Debug, Clone, Copy)]
pub enum EmbeddedMetadata {
    Dir,
    File { len: u64 },
}

impl Metadata for EmbeddedMetadata {
    fn is_dir(&self) -> bool {
        matches!(self, Self::Dir)
    }

    fn modified(&self) -> io::Result<SystemTime> {
        Err(io::Error::from(io::ErrorKind::Unsupported))
    }

    fn len(&self) -> u64 {
        match *self {
            Self::Dir => 0,
            Self::File { len } => len,
        }
    }
}

fn collect_entries(
    dir: &'static Dir<'static>,
    entries: &mut HashMap<&'static Path, EmbeddedEntry>,
) {
    for file in dir.files() {
        entries.insert(file.path(), EmbeddedEntry::File(EmbeddedFile::new(file)));
    }
    for subdir in dir.dirs() {
        entries.insert(subdir.path(), EmbeddedEntry::Dir);
        collect_entries(subdir, entries);
    }
}

/// Strips leading `.` or `/` components so paths joined by `ServeDir`
/// match the relative paths stored in `include_dir::Dir`.
fn normalize_path(mut path: &Path) -> &Path {
    while let Ok(stripped) = path.strip_prefix(".").or_else(|_| path.strip_prefix("/")) {
        path = stripped;
    }
    path
}

fn compute_etag(contents: &[u8]) -> HeaderValue {
    let digest = Sha256::digest(contents);
    let mut etag = String::with_capacity(2 + digest.len() * 2);
    etag.push('"');
    for byte in digest {
        let _ = write!(etag, "{byte:02x}");
    }
    etag.push('"');
    HeaderValue::from_str(&etag).expect("SHA-256 hex ETag is valid ASCII")
}

/// Middleware that attaches the precomputed SHA-256 `ETag` from [`IncludeDirBackend`]
/// and evaluates `If-Match` and `If-None-Match` preconditions.
pub async fn etag_middleware(request: Request, next: Next) -> Response {
    let if_match = request.headers().get(header::IF_MATCH).cloned();
    let if_none_match = request.headers().get(header::IF_NONE_MATCH).cloned();

    SERVED_ETAG
        .scope(Cell::new(None), async move {
            let mut response = next.run(request).await;

            if !matches!(
                response.status(),
                StatusCode::OK | StatusCode::PARTIAL_CONTENT | StatusCode::RANGE_NOT_SATISFIABLE
            ) {
                return response;
            }

            let Some(etag) = SERVED_ETAG.with(Cell::take) else {
                return response;
            };

            if let Some(ref value) = if_match
                && !value.is_empty()
                && !if_match_passes(value.as_bytes(), etag.as_bytes())
            {
                let mut res = StatusCode::PRECONDITION_FAILED.into_response();
                if let Some(vary) = response.headers().get(header::VARY).cloned() {
                    res.headers_mut().insert(header::VARY, vary);
                }
                return res;
            }

            if let Some(ref value) = if_none_match
                && !value.is_empty()
                && !if_none_match_passes(value.as_bytes(), etag.as_bytes())
            {
                let mut res = StatusCode::NOT_MODIFIED.into_response();
                if let Some(vary) = response.headers().get(header::VARY).cloned() {
                    res.headers_mut().insert(header::VARY, vary);
                }
                res.headers_mut().insert(header::ETAG, etag);
                return res;
            }

            response.headers_mut().insert(header::ETAG, etag);
            response
        })
        .await
}

fn if_match_passes(header: &[u8], etag: &[u8]) -> bool {
    let trimmed = trim_ows(header);
    if trimmed == b"*" {
        return true;
    }
    for_each_etag(trimmed, |tag| !tag.starts_with(b"W/") && tag == etag)
}

fn if_none_match_passes(header: &[u8], etag: &[u8]) -> bool {
    let trimmed = trim_ows(header);
    if trimmed == b"*" {
        return false;
    }
    !for_each_etag(trimmed, |tag| {
        let tag = tag.strip_prefix(b"W/").unwrap_or(tag);
        tag == etag
    })
}

fn for_each_etag(header: &[u8], mut predicate: impl FnMut(&[u8]) -> bool) -> bool {
    let mut start = 0;
    let mut in_quotes = false;
    for (i, &byte) in header.iter().enumerate() {
        match byte {
            b'"' => in_quotes = !in_quotes,
            b',' if !in_quotes => {
                let trimmed = trim_ows(&header[start..i]);
                if !trimmed.is_empty() && predicate(trimmed) {
                    return true;
                }
                start = i + 1;
            }
            _ => {}
        }
    }
    let trimmed = trim_ows(&header[start..]);
    !trimmed.is_empty() && predicate(trimmed)
}

fn trim_ows(bytes: &[u8]) -> &[u8] {
    let Some(start) = bytes.iter().position(|&b| b != b' ' && b != b'\t') else {
        return &[];
    };
    let end = bytes
        .iter()
        .rposition(|&b| b != b' ' && b != b'\t')
        .map_or(0, |i| i + 1);
    &bytes[start..end]
}
