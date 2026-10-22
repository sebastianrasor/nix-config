use flate2::{
    Compression,
    write::{DeflateEncoder, GzEncoder},
};
use minijinja::Environment;
use sha2::{Digest, Sha256};
use std::{
    env,
    error::Error,
    fs,
    io::{self, Write},
    path::{Path, PathBuf},
};
use walkdir::WalkDir;

const BROTLI_BUFFER_SIZE: usize = 131_072;
const BROTLI_QUALITY: u32 = 11;
const BROTLI_WINDOW_SIZE: u32 = 24;
const ZSTD_MAX_LEVEL: i32 = 19;

const TURNSTILE_SITE_KEY: &str = if cfg!(debug_assertions) {
    "1x00000000000000000000BB"
} else {
    "0x4AAAAAAACsmQqydNII05ly"
};

type Compressor = fn(&[u8], &mut Vec<u8>) -> io::Result<()>;

// Extensions must match those expected by `tower_http::services::ServeDir`'s
// `precompressed_br`, `precompressed_deflate` (`.zz`), `precompressed_gzip`,
// and `precompressed_zstd` methods.
const COMPRESSORS: &[(&str, Compressor)] = &[
    ("br", compress_brotli),
    ("zz", compress_deflate),
    ("gz", compress_gzip),
    ("zst", compress_zstd),
];

fn main() -> Result<(), Box<dyn Error>> {
    println!("cargo::rerun-if-changed=build.rs");
    println!("cargo::rerun-if-env-changed=TARGETS_DIR");

    let out_dir = PathBuf::from(env::var("OUT_DIR")?).join("assets");
    if out_dir.exists() {
        fs::remove_dir_all(&out_dir)?;
    }
    fs::create_dir_all(&out_dir)?;

    if let Ok(targets_dir) = env::var("TARGETS_DIR") {
        process_directory(Path::new(&targets_dir), &out_dir)?;
    } else {
        println!("cargo::warning=TARGETS_DIR is not set; skipping targets assets");
    }

    process_directory(Path::new("assets"), &out_dir)?;

    Ok(())
}

/// Recursively copies all files in `src_dir` to `out_dir` and generates
/// compressed variants.
fn process_directory(src_dir: &Path, out_dir: &Path) -> Result<(), Box<dyn Error>> {
    for entry in WalkDir::new(src_dir)
        .follow_links(true)
        .sort_by_key(|entry| is_template(entry.path()))
    {
        let entry = entry?;
        let path = entry.path();
        println!("cargo::rerun-if-changed={}", path.display());

        if entry.file_type().is_file() {
            process_asset(path, src_dir, out_dir)?;
        }
    }

    Ok(())
}

/// Copies a single asset to `out_dir` and generates compressed variants.
fn process_asset(src_path: &Path, base_dir: &Path, out_dir: &Path) -> Result<(), Box<dyn Error>> {
    let relative_path = src_path.strip_prefix(base_dir)?;
    let target_path = out_dir.join(relative_path);

    if let Some(parent) = target_path.parent() {
        fs::create_dir_all(parent)?;
    }

    let data = if is_template(src_path) {
        render_template(src_path, out_dir)?.into_bytes()
    } else {
        fs::read(src_path)?
    };

    if src_path.extension().is_some_and(|ext| ext == "headers") {
        fs::write(&target_path, &data)?;
        return Ok(());
    }

    write_with_digest(&target_path, &data)?;

    let mut compressed = Vec::new();
    for &(ext, compress) in COMPRESSORS {
        compressed.clear();
        compress(&data, &mut compressed)?;

        let compressed_path = target_path.with_added_extension(ext);
        write_with_digest(&compressed_path, &compressed)?;
    }

    Ok(())
}

fn is_template(path: &Path) -> bool {
    path.extension()
        .is_some_and(|ext| ext == "html" || ext == "headers")
}

fn render_template(src_path: &Path, out_dir: &Path) -> Result<String, Box<dyn Error>> {
    let out_dir = out_dir.to_path_buf();
    let mut env = Environment::new();
    env.add_global("turnstile_site_key", TURNSTILE_SITE_KEY);
    env.add_function("asset", move |path: &str| {
        let relative_path = path.strip_prefix('/').unwrap_or(path);
        let sha256_path = out_dir.join(relative_path).with_added_extension("sha256");

        fs::read_to_string(&sha256_path).map_or_else(
            |err| {
                println!(
                    "cargo::warning=failed to read SHA-256 digest at {}: {err}",
                    sha256_path.display()
                );
                path.to_owned()
            },
            |digest| format!("{path}?v={digest}"),
        )
    });

    let template = fs::read_to_string(src_path)?;

    Ok(env.render_str(&template, ())?)
}

fn write_with_digest(path: &Path, data: &[u8]) -> io::Result<()> {
    fs::write(path, data)?;

    let digest = Sha256::digest(data);
    fs::write(path.with_added_extension("sha256"), hex::encode(digest))
}

fn compress_brotli(data: &[u8], writer: &mut impl Write) -> io::Result<()> {
    let mut encoder = brotli::CompressorWriter::new(
        writer,
        BROTLI_BUFFER_SIZE,
        BROTLI_QUALITY,
        BROTLI_WINDOW_SIZE,
    );
    encoder.write_all(data)?;
    encoder.flush()
}

fn compress_deflate(data: &[u8], writer: &mut impl Write) -> io::Result<()> {
    let mut encoder = DeflateEncoder::new(writer, Compression::best());
    encoder.write_all(data)?;
    encoder.finish()?;
    Ok(())
}

fn compress_gzip(data: &[u8], writer: &mut impl Write) -> io::Result<()> {
    let mut encoder = GzEncoder::new(writer, Compression::best());
    encoder.write_all(data)?;
    encoder.finish()?;
    Ok(())
}

fn compress_zstd(data: &[u8], writer: &mut impl Write) -> io::Result<()> {
    zstd::stream::copy_encode(data, writer, ZSTD_MAX_LEVEL)
}
