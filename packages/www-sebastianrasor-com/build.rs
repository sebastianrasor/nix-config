use flate2::Compression;
use flate2::write::{DeflateEncoder, GzEncoder};
use std::env;
use std::error::Error;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

const BROTLI_BUFFER_SIZE: usize = 131_072;
const BROTLI_QUALITY: u32 = 11;
const BROTLI_WINDOW_SIZE: u32 = 24;
const ZSTD_MAX_LEVEL: i32 = 19;

fn main() -> Result<(), Box<dyn Error>> {
    println!("cargo::rerun-if-changed=build.rs");
    println!("cargo::rerun-if-changed=assets");

    let out_dir = PathBuf::from(env::var("OUT_DIR")?);
    let assets_dir = Path::new("assets");
    let dest_dir = out_dir.join("assets");

    reset_directory(&dest_dir)?;

    for entry in WalkDir::new(assets_dir) {
        let entry = entry?;
        if entry.file_type().is_file() {
            let path = entry.path();
            process_asset(path, assets_dir, &dest_dir)
                .map_err(|err| format!("failed to process asset {}: {err}", path.display()))?;
        }
    }

    Ok(())
}

/// Removes the directory if it exists and recreates an empty one.
fn reset_directory(dir: &Path) -> std::io::Result<()> {
    if dir.exists() {
        fs::remove_dir_all(dir)?;
    }
    fs::create_dir_all(dir)
}

/// Copies a single asset to the destination directory and generates compressed variants.
fn process_asset(src_path: &Path, base_dir: &Path, dest_dir: &Path) -> Result<(), Box<dyn Error>> {
    let relative_path = src_path.strip_prefix(base_dir)?;
    let target_path = dest_dir.join(relative_path);

    if let Some(parent) = target_path.parent() {
        fs::create_dir_all(parent)?;
    }

    let data = fs::read(src_path)?;
    fs::write(&target_path, &data)?;

    compress_brotli(&target_path, &data)?;
    compress_deflate(&target_path, &data)?;
    compress_gzip(&target_path, &data)?;
    compress_zstd(&target_path, &data)?;

    Ok(())
}

/// Appends an extension (e.g., "asset.js" -> "asset.js.br") and creates the output file.
fn create_compressed_file(base_path: &Path, ext: &str) -> std::io::Result<File> {
    File::create(base_path.with_added_extension(ext))
}

fn compress_brotli(target: &Path, data: &[u8]) -> std::io::Result<()> {
    let file = create_compressed_file(target, "br")?;
    let mut encoder =
        brotli::CompressorWriter::new(file, BROTLI_BUFFER_SIZE, BROTLI_QUALITY, BROTLI_WINDOW_SIZE);
    encoder.write_all(data)?;
    encoder.flush()
}

fn compress_deflate(target: &Path, data: &[u8]) -> std::io::Result<()> {
    let file = create_compressed_file(target, "zz")?;
    let mut encoder = DeflateEncoder::new(file, Compression::best());
    encoder.write_all(data)?;
    encoder.finish().map(|_| ())
}

fn compress_gzip(target: &Path, data: &[u8]) -> std::io::Result<()> {
    let file = create_compressed_file(target, "gz")?;
    let mut encoder = GzEncoder::new(file, Compression::best());
    encoder.write_all(data)?;
    encoder.finish().map(|_| ())
}

fn compress_zstd(target: &Path, data: &[u8]) -> std::io::Result<()> {
    let file = create_compressed_file(target, "zst")?;
    let mut encoder = zstd::Encoder::new(file, ZSTD_MAX_LEVEL)?;
    encoder.write_all(data)?;
    encoder.finish().map(|_| ())
}
