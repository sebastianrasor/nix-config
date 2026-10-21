use include_dir::{Dir, DirEntry, File};
use std::{
    future::{Ready, ready},
    io::{self, Cursor},
    path::PathBuf,
    pin::Pin,
    task::{Context, Poll},
    time::SystemTime,
};
use tokio::io::{AsyncRead, AsyncSeek, ReadBuf};
use tower_http::services::fs::{Backend, File as FileTrait, Metadata};

#[derive(Debug, Clone)]
pub struct IncludeDirBackend {
    dir: &'static Dir<'static>,
}

impl From<&'static Dir<'static>> for IncludeDirBackend {
    fn from(dir: &'static Dir<'static>) -> Self {
        Self { dir }
    }
}

impl Backend for IncludeDirBackend {
    type File = IncludeDirBackendFile;
    type Metadata = IncludeDirBackendMetadata;
    type OpenFuture = Ready<io::Result<Self::File>>;
    type MetadataFuture = Ready<io::Result<Self::Metadata>>;

    fn open(&self, path: PathBuf) -> Self::OpenFuture {
        let path = path.strip_prefix("./").unwrap_or(&path);

        let Some(file) = self.dir.get_file(path) else {
            return ready(Err(io::Error::from(io::ErrorKind::NotFound)));
        };

        ready(Ok(file.into()))
    }

    fn metadata(&self, path: PathBuf) -> Self::MetadataFuture {
        let path = path.strip_prefix("./").unwrap_or(&path);
        if path.as_os_str().is_empty() {
            return ready(Ok(IncludeDirBackendMetadata::Dir));
        }

        let Some(entry) = self.dir.get_entry(path) else {
            return ready(Err(io::Error::from(io::ErrorKind::NotFound)));
        };

        ready(Ok(entry.into()))
    }
}

#[derive(Debug, Clone)]
pub struct IncludeDirBackendFile {
    cursor: Cursor<&'static [u8]>,
    metadata: IncludeDirBackendMetadata,
}

impl From<&'static File<'static>> for IncludeDirBackendFile {
    fn from(file: &'static File<'static>) -> Self {
        Self {
            cursor: Cursor::new(file.contents()),
            metadata: file.into(),
        }
    }
}

impl FileTrait for IncludeDirBackendFile {
    type Metadata = IncludeDirBackendMetadata;
    type MetadataFuture<'a> = Ready<io::Result<Self::Metadata>>;
    fn metadata(&self) -> Self::MetadataFuture<'_> {
        ready(Ok(self.metadata))
    }
}

impl AsyncRead for IncludeDirBackendFile {
    fn poll_read(
        mut self: Pin<&mut Self>,
        cx: &mut Context<'_>,
        buf: &mut ReadBuf<'_>,
    ) -> Poll<io::Result<()>> {
        Pin::new(&mut self.cursor).poll_read(cx, buf)
    }
}

impl AsyncSeek for IncludeDirBackendFile {
    fn start_seek(mut self: Pin<&mut Self>, position: io::SeekFrom) -> io::Result<()> {
        Pin::new(&mut self.cursor).start_seek(position)
    }
    fn poll_complete(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<io::Result<u64>> {
        Pin::new(&mut self.cursor).poll_complete(cx)
    }
}

#[derive(Debug, Clone, Copy)]
pub enum IncludeDirBackendMetadata {
    Dir,
    File { len: u64 },
}

impl From<&'static File<'static>> for IncludeDirBackendMetadata {
    fn from(file: &'static File<'static>) -> Self {
        Self::File {
            len: file.contents().len() as u64,
        }
    }
}

impl From<&'static DirEntry<'static>> for IncludeDirBackendMetadata {
    fn from(entry: &'static DirEntry<'static>) -> Self {
        match entry {
            DirEntry::Dir(_) => Self::Dir,
            DirEntry::File(file) => Self::from(file),
        }
    }
}

impl Metadata for IncludeDirBackendMetadata {
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
