use std::{
    collections::HashMap,
    env,
    error::Error,
    fs,
    io::{self, Read},
    mem,
    path::{Path, PathBuf},
    sync::Mutex,
};

use brotli::CompressorReader;
use flate2::{
    Compression,
    read::{GzEncoder, ZlibEncoder},
};
use handlebars::{
    Context, Handlebars, Helper, HelperResult, Output, PathAndJson, RenderContext,
    RenderErrorReason, to_json,
};
use sha2::{Digest, Sha256};
use walkdir::WalkDir;

const ASSETS_DIR: &str = "assets";

const DIGEST_PREFIX: &str = "/by-digest/";

const BROTLI_BUFFER_SIZE: usize = 4096;
const BROTLI_QUALITY: u32 = 11;
const BROTLI_LGWIN: u32 = 24;
const ZSTD_COMPRESSION_LEVEL: i32 = 19;

struct AssetTable {
    out_dir: PathBuf,
    assets: Vec<String>,
    map: phf_codegen::Map<'static, String>,
    digest_paths: HashMap<String, String>,
}

impl AssetTable {
    fn new(out_dir: PathBuf) -> Self {
        Self {
            out_dir,
            assets: Vec::new(),
            map: phf_codegen::Map::new(),
            digest_paths: HashMap::new(),
        }
    }

    fn add(&mut self, path: &Path, bytes: &[u8], headers: &[(String, String)]) -> io::Result<()> {
        let identity = self.write_blob(bytes)?;
        let compressed = self.write_compressed(bytes)?;
        let content_type = mime_guess::from_path(path).first_or_text_plain();

        let asset_ref = format!("&CONST_ASSETS[{}]", self.assets.len());
        self.assets.push(const_asset(
            content_type.as_ref(),
            &identity,
            &compressed,
            headers,
        ));

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
        fs::write(self.out_dir.join(&digest), bytes)?;
        Ok(digest)
    }

    fn write(&self) -> io::Result<()> {
        let len = self.assets.len();
        let assets = self.assets.join(",\n");
        let map = self.map.build();
        fs::write(
            self.out_dir.join("asset_table.rs"),
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

fn const_asset(
    content_type: &str,
    identity: &str,
    compressed: &[(&str, String); 4],
    headers: &[(String, String)],
) -> String {
    let compressed = compressed
        .each_ref()
        .map(|(encoding, digest)| encoded_asset(encoding, digest))
        .join(", ");
    format!(
        "ConstAsset {{ content_type: {content_type:?}, identity: {}, compressed: &[{compressed}], headers: &{headers:?} }}",
        encoded_asset("Identity", identity),
    )
}

fn encoded_asset(encoding: &str, digest: &str) -> String {
    format!(
        r#"EncodedAsset {{
            encoding: Encoding::{encoding},
            etag: "\"{digest}\"",
            data: include_bytes!(concat!(env!("OUT_DIR"), "/{digest}")),
        }}"#
    )
}

fn url_path(path: &Path) -> String {
    let path = path
        .strip_prefix(ASSETS_DIR)
        .expect("asset must be in ASSETS_DIR")
        .to_str()
        .expect("asset paths must be valid UTF-8");
    let path = match path.strip_suffix("index.html") {
        Some(dir) if dir.is_empty() || dir.ends_with('/') => dir,
        _ => path.strip_suffix(".html").unwrap_or(path),
    };
    format!("/{path}")
}

fn main() -> Result<(), Box<dyn Error>> {
    println!("cargo::rerun-if-changed={ASSETS_DIR}");

    let mut table = AssetTable::new(PathBuf::from(env::var("OUT_DIR")?));
    let mut templates = Vec::new();

    for entry in WalkDir::new(ASSETS_DIR) {
        let entry = entry?;
        if !entry.file_type().is_file() {
            continue;
        }

        let path = entry.into_path();
        if path.extension().is_some_and(|ext| ext == "hbs") {
            templates.push(path);
        } else {
            table.add(&path, &fs::read(&path)?, &[])?;
        }
    }

    let is_debug = env::var_os("CARGO_CFG_DEBUG_ASSERTIONS").is_some();

    let template_headers = Mutex::new(Vec::new());
    let mut handlebars = Handlebars::new();
    handlebars.set_strict_mode(true);
    handlebars.register_helper(
        "header",
        Box::new(
            |h: &Helper,
             _: &Handlebars,
             _: &Context,
             _: &mut RenderContext,
             _: &mut dyn Output|
             -> HelperResult {
                let mut params = h.params().iter().map(PathAndJson::render);
                let name = params
                    .next()
                    .ok_or(RenderErrorReason::ParamNotFoundForIndex("header", 0))?;
                template_headers.lock().unwrap().push((name, params.collect()));
                Ok(())
            },
        ),
    );

    let turnstile_sitekey = if is_debug {
        "1x00000000000000000000BB"
    } else {
        "0x4AAAAAAACsmQqydNII05ly"
    };
    // Templates may reference each other's output, so render in passes until none are left.
    while !templates.is_empty() {
        let template_data = HashMap::from([
            ("assets", to_json(&table.digest_paths)),
            ("turnstile_sitekey", to_json(turnstile_sitekey)),
        ]);
        let pending = templates.len();
        let mut error = None;
        for path in mem::take(&mut templates) {
            let result = handlebars.render_template(&fs::read_to_string(&path)?, &template_data);
            let headers = mem::take(&mut *template_headers.lock().unwrap());
            match result {
                Ok(rendered) => table.add(&path.with_extension(""), rendered.as_bytes(), &headers)?,
                Err(e) => {
                    templates.push(path);
                    error = Some(e);
                }
            }
        }
        if templates.len() == pending {
            // No progress: fail in release, fall back to lenient rendering in debug.
            if !(is_debug && handlebars.strict_mode()) {
                return Err(error.unwrap().into());
            }
            handlebars.set_strict_mode(false);
        }
    }

    table.write()?;

    Ok(())
}
