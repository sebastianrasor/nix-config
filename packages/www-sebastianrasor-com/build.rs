use std::{
    collections::HashMap,
    env,
    error::Error,
    fs,
    io::{self, Read},
    path::{Path, PathBuf},
};

use brotli::CompressorReader;
use flate2::{
    Compression,
    read::{GzEncoder, ZlibEncoder},
};
use handlebars::{Handlebars, to_json};
use sha2::{Digest, Sha256};
use walkdir::WalkDir;

const BLOB_SUBDIR: &str = "assets";

const DIGEST_PREFIX: &str = "/by-digest/";

const BROTLI_BUFFER_SIZE: usize = 4096;
const BROTLI_QUALITY: u32 = 11;
const BROTLI_LGWIN: u32 = 24;
const ZSTD_COMPRESSION_LEVEL: i32 = 19;

struct AssetTable {
    blob_dir: PathBuf,
    assets: Vec<String>,
    map: phf_codegen::Map<'static, String>,
    digest_paths: HashMap<String, String>,
}

impl AssetTable {
    fn new(out_dir: &Path) -> io::Result<Self> {
        let blob_dir = out_dir.join(BLOB_SUBDIR);
        if blob_dir.exists() {
            fs::remove_dir_all(&blob_dir)?;
        }
        fs::create_dir_all(&blob_dir)?;

        Ok(Self {
            blob_dir,
            assets: Vec::new(),
            map: phf_codegen::Map::new(),
            digest_paths: HashMap::new(),
        })
    }

    fn add(&mut self, path: &Path, bytes: &[u8]) -> io::Result<()> {
        let identity = self.write_blob(bytes)?;
        let compressed = self.write_compressed(bytes)?;
        let content_type = mime_guess::from_path(path).first_or_text_plain();

        let asset_ref = format!("&CONST_ASSETS[{}]", self.assets.len());
        self.assets
            .push(const_asset(content_type.as_ref(), &identity, &compressed));

        let url_path = url_path(path);
        let digest_path = format!("{DIGEST_PREFIX}{identity}{url_path}");
        self.map.entry(url_path.clone(), asset_ref.clone());
        self.map.entry(digest_path.clone(), asset_ref);
        self.digest_paths.insert(url_path, digest_path);

        Ok(())
    }

    fn write_compressed(&self, bytes: &[u8]) -> io::Result<[(&'static str, String); 4]> {
        Ok([
            (
                "Br",
                self.write_blob(CompressorReader::new(
                    bytes,
                    BROTLI_BUFFER_SIZE,
                    BROTLI_QUALITY,
                    BROTLI_LGWIN,
                ))?,
            ),
            (
                "Zstd",
                self.write_blob(zstd::stream::read::Encoder::new(
                    bytes,
                    ZSTD_COMPRESSION_LEVEL,
                )?)?,
            ),
            (
                "Gzip",
                self.write_blob(GzEncoder::new(bytes, Compression::best()))?,
            ),
            (
                "Deflate",
                self.write_blob(ZlibEncoder::new(bytes, Compression::best()))?,
            ),
        ])
    }

    fn write_blob(&self, mut reader: impl Read) -> io::Result<String> {
        let mut bytes = Vec::new();
        reader.read_to_end(&mut bytes)?;
        let digest = hex::encode(Sha256::digest(&bytes));
        fs::write(self.blob_dir.join(&digest), bytes)?;
        Ok(digest)
    }

    fn write_to(&self, path: &Path) -> io::Result<()> {
        let len = self.assets.len();
        let assets = self.assets.join(",\n");
        let map = self.map.build();
        fs::write(
            path,
            format!(
                r"
                    const DIGEST_PREFIX: &str = {DIGEST_PREFIX:?};
                    static CONST_ASSETS: [ConstAsset; {len}] = [{assets}];
                    #[allow(clippy::unreadable_literal)]
                    static ASSET_MAP: phf::Map<&'static str, &'static ConstAsset> = {map};
                "
            ),
        )
    }
}

fn const_asset(content_type: &str, identity: &str, compressed: &[(&str, String)]) -> String {
    let compressed: Vec<_> = compressed
        .iter()
        .map(|(encoding, digest)| encoded_asset(encoding, digest))
        .collect();
    format!(
        "ConstAsset {{ content_type: {content_type:?}, identity: {}, compressed: &[{}] }}",
        encoded_asset("Identity", identity),
        compressed.join(", "),
    )
}

fn encoded_asset(encoding: &str, digest: &str) -> String {
    format!(
        r#"EncodedAsset {{
            encoding: Encoding::{encoding},
            etag: "\"{digest}\"",
            data: include_bytes!(concat!(env!("OUT_DIR"), "/{BLOB_SUBDIR}/{digest}")),
        }}"#
    )
}

fn url_path(path: &Path) -> String {
    let path = path.to_str().expect("asset paths must be valid UTF-8");
    let path = match path.strip_suffix("index.html") {
        Some(dir) if dir.is_empty() || dir.ends_with('/') => dir,
        _ => path.strip_suffix(".html").unwrap_or(path),
    };
    format!("/{path}")
}

fn main() -> Result<(), Box<dyn Error>> {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR")?);
    let out_dir = PathBuf::from(env::var("OUT_DIR")?);

    println!("cargo::rerun-if-env-changed=TARGETS_DIR");
    let asset_dirs = [
        Some(manifest_dir.join("assets")),
        env::var_os("TARGETS_DIR").map(PathBuf::from),
    ];

    let mut table = AssetTable::new(&out_dir)?;
    let mut templates = Vec::new();

    for root in asset_dirs.iter().flatten() {
        println!("cargo::rerun-if-changed={}", root.display());
        for entry in WalkDir::new(root) {
            let entry = entry?;
            if !entry.file_type().is_file() {
                continue;
            }

            let asset_path = entry.path().strip_prefix(root)?;

            if asset_path.extension().is_some_and(|ext| ext == "hbs") {
                templates.push((entry.path().to_path_buf(), asset_path.with_extension("")));
            } else {
                table.add(asset_path, &fs::read(entry.path())?)?;
            }
        }
    }

    let mut handlebars = Handlebars::new();
    handlebars.set_strict_mode(true);

    let turnstile_sitekey = if env::var_os("CARGO_CFG_DEBUG_ASSERTIONS").is_some() {
        "1x00000000000000000000BB"
    } else {
        "0x4AAAAAAACsmQqydNII05ly"
    };
    let template_data = HashMap::from([
        ("assets", to_json(&table.digest_paths)),
        ("turnstile_sitekey", to_json(turnstile_sitekey)),
    ]);

    for (template_path, asset_path) in templates {
        let template = fs::read_to_string(&template_path)?;
        let rendered = handlebars.render_template(&template, &template_data)?;
        table.add(&asset_path, rendered.as_bytes())?;
    }

    table.write_to(&out_dir.join("asset_table.rs"))?;

    Ok(())
}
