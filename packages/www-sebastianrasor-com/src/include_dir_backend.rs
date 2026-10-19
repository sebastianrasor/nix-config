use std::{
    collections::HashMap,
    future::{Ready, ready},
    hash::{DefaultHasher, Hasher},
    io::{self, Cursor, SeekFrom},
    path::{Path, PathBuf},
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
    time::{Duration, SystemTime},
};

use include_dir::Dir;
use tokio::io::{AsyncRead, AsyncSeek, ReadBuf};
use tower_http::services::fs::{Backend, File, Metadata};

/// Maximum nanosecond offset (~36.5 years) for synthetic modification times,
/// keeping `Last-Modified` between 1970 and 2006 (never in the future per
/// RFC 9110 §8.8.2) while preserving 60 bits of the content hash for `ETag`s.
const MAX_SYNTHETIC_MODIFIED_NANOS: u64 = (1 << 60) - 1;

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
            Some(EmbeddedEntry::File(file)) => Ok(file.clone()),
            Some(EmbeddedEntry::Dir) | None => Err(io::Error::from(io::ErrorKind::NotFound)),
        };

        ready(result)
    }

    fn metadata(&self, path: PathBuf) -> Self::MetadataFuture {
        let result = match self.entries.get(normalize_path(&path)) {
            Some(EmbeddedEntry::Dir) => Ok(EmbeddedMetadata::Dir),
            Some(EmbeddedEntry::File(file)) => Ok(file.metadata),
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
}

impl EmbeddedFile {
    fn new(file: &'static include_dir::File<'static>) -> Self {
        let contents = file.contents();
        Self {
            cursor: Cursor::new(contents),
            metadata: EmbeddedMetadata::File {
                len: contents.len() as u64,
                modified: content_modified_time(contents),
            },
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
    File { len: u64, modified: SystemTime },
}

impl Metadata for EmbeddedMetadata {
    fn is_dir(&self) -> bool {
        matches!(self, Self::Dir)
    }

    fn modified(&self) -> io::Result<SystemTime> {
        match *self {
            Self::Dir => Err(io::Error::from(io::ErrorKind::Unsupported)),
            Self::File { modified, .. } => Ok(modified),
        }
    }

    fn len(&self) -> u64 {
        match *self {
            Self::Dir => 0,
            Self::File { len, .. } => len,
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

/// Derives a deterministic, synthetic modification timestamp from a file's contents.
///
/// `include_dir` does not embed filesystem timestamps by default (and Nix builds
/// normalize source mtimes to the Unix epoch), while `tower_http::services::ServeDir`
/// derives `ETag` headers from `(modified(), len())`. Hashing the file contents into a
/// bounded `SystemTime` allows `ServeDir` to generate content-based `ETag`s without
/// emitting future `Last-Modified` dates.
fn content_modified_time(contents: &[u8]) -> SystemTime {
    let mut hasher = DefaultHasher::new();
    hasher.write(contents);
    let nanos = hasher.finish() & MAX_SYNTHETIC_MODIFIED_NANOS;
    SystemTime::UNIX_EPOCH + Duration::from_nanos(nanos)
}

/// Strips leading `.` or `/` components so paths joined by `ServeDir`
/// match the relative paths stored in `include_dir::Dir`.
fn normalize_path(mut path: &Path) -> &Path {
    while let Ok(stripped) = path.strip_prefix(".").or_else(|_| path.strip_prefix("/")) {
        path = stripped;
    }
    path
}
