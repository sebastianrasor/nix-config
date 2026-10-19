//! Vibe coded with Gemini 4

use std::{
    future::{ready, Ready},
    io::{self, Cursor, SeekFrom},
    path::{Component, Path, PathBuf},
    pin::Pin,
    task::{Context, Poll},
    time::SystemTime,
};

use include_dir::{Dir, DirEntry};
use tokio::io::{AsyncRead, AsyncSeek, ReadBuf};
use tower_http::services::fs::{Backend, File, Metadata};

/// A `tower_http::services::fs::Backend` backed by an `include_dir::Dir`.
#[derive(Debug, Clone, Copy)]
pub struct IncludeDirBackend {
    dir: &'static Dir<'static>,
}

impl IncludeDirBackend {
    pub const fn new(dir: &'static Dir<'static>) -> Self {
        Self { dir }
    }
}

impl Backend for IncludeDirBackend {
    type File = EmbeddedFile;
    type Metadata = EmbeddedMetadata;
    type OpenFuture = Ready<io::Result<Self::File>>;
    type MetadataFuture = Ready<io::Result<Self::Metadata>>;

    fn open(&self, path: PathBuf) -> Self::OpenFuture {
        let normalized = normalize_path(&path);

        let result = if normalized.as_os_str().is_empty() {
            // Root directory cannot be opened as a file.
            // ServeDir maps ErrorKind::NotFound to 404 (or triggers fallback).
            Err(io::Error::from(io::ErrorKind::NotFound))
        } else {
            self.dir
                .get_file(&normalized)
                .map(EmbeddedFile::new)
                .ok_or_else(|| io::Error::from(io::ErrorKind::NotFound))
        };

        ready(result)
    }

    fn metadata(&self, path: PathBuf) -> Self::MetadataFuture {
        let normalized = normalize_path(&path);

        let result = if normalized.as_os_str().is_empty() {
            Ok(EmbeddedMetadata::dir())
        } else {
            match self.dir.get_entry(&normalized) {
                Some(DirEntry::Dir(_)) => Ok(EmbeddedMetadata::dir()),
                Some(DirEntry::File(file)) => Ok(EmbeddedMetadata::from_file(file)),
                None => Err(io::Error::from(io::ErrorKind::NotFound)),
            }
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
        Self {
            cursor: Cursor::new(file.contents()),
            metadata: EmbeddedMetadata::from_file(file),
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
pub struct EmbeddedMetadata {
    is_dir: bool,
    len: u64,
    modified: Option<SystemTime>,
}

impl EmbeddedMetadata {
    const fn dir() -> Self {
        Self {
            is_dir: true,
            len: 0,
            modified: None,
        }
    }

    fn from_file(file: &'static include_dir::File<'static>) -> Self {
        Self {
            is_dir: false,
            len: file.contents().len() as u64,
            // Requires `include_dir = { version = "0.7", features = ["metadata"] }`.
            // If you don't enable `metadata` on `include_dir`, set this to `None`.
            modified: file.metadata().map(|m| m.modified()),
        }
    }
}

impl Metadata for EmbeddedMetadata {
    fn is_dir(&self) -> bool {
        self.is_dir
    }

    fn modified(&self) -> io::Result<SystemTime> {
        self.modified
            .ok_or_else(|| io::Error::from(io::ErrorKind::Unsupported))
    }

    fn len(&self) -> u64 {
        self.len
    }
}

/// Strips leading `.` or `/` components so paths joined by `ServeDir`
/// match the relative paths stored in `include_dir::Dir`.
fn normalize_path(path: &Path) -> PathBuf {
    path.components()
        .filter_map(|component| match component {
            Component::Normal(part) => Some(part),
            _ => None,
        })
        .collect()
}
