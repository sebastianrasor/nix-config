use std::{
    collections::HashMap,
    env,
    error::Error,
    fs::{self, File},
    io::{self, BufWriter, Read, Write},
    path::{Path, PathBuf},
};

use brotli::CompressorReader;
use flate2::{
    Compression,
    read::{GzEncoder, ZlibEncoder},
};
use handlebars::{
    Context, Handlebars, Helper, HelperResult, Output, RenderContext, RenderErrorReason,
};
use sha2::{Digest, Sha256};
use walkdir::WalkDir;

type BuildResult<T> = Result<T, Box<dyn Error>>;

const BLOB_SUBDIR: &str = "assets";

/// URL prefix for the immutable, content-addressed copy of every asset.
const DIGEST_PREFIX: &str = "/by-digest/";

const BROTLI_BUFFER_SIZE: usize = 4096;
const BROTLI_QUALITY: u32 = 11;
const BROTLI_LGWIN: u32 = 24;

struct CompressedCoding {
    encoding_variant: &'static str,
    encode: fn(&[u8]) -> io::Result<Vec<u8>>,
}

const COMPRESSED_CODINGS: [CompressedCoding; 4] = [
    CompressedCoding {
        encoding_variant: "Br",
        encode: |bytes| {
            read_all(CompressorReader::new(
                bytes,
                BROTLI_BUFFER_SIZE,
                BROTLI_QUALITY,
                BROTLI_LGWIN,
            ))
        },
    },
    CompressedCoding {
        encoding_variant: "Zstd",
        encode: |bytes| zstd::encode_all(bytes, 19),
    },
    CompressedCoding {
        encoding_variant: "Gzip",
        encode: |bytes| read_all(GzEncoder::new(bytes, Compression::best())),
    },
    // RFC 9110 §8.4.1.2: the "deflate" content-coding is the zlib format, not raw DEFLATE.
    CompressedCoding {
        encoding_variant: "Deflate",
        encode: |bytes| read_all(ZlibEncoder::new(bytes, Compression::best())),
    },
];

fn read_all(mut reader: impl Read) -> io::Result<Vec<u8>> {
    let mut buf = Vec::new();
    reader.read_to_end(&mut buf)?;
    Ok(buf)
}

/// Accumulates the generated `CONST_ASSETS` array and `ASSET_MAP` lookup table.
///
/// Encoded bytes are written to content-addressed files in [`BLOB_SUBDIR`] and embedded with
/// `include_bytes!`, which keeps the generated source small and readable.
struct AssetTable {
    blob_dir: PathBuf,
    assets: Vec<String>,
    map: phf_codegen::Map<'static, String>,
    digest_paths: HashMap<String, String>,
}

impl AssetTable {
    fn new(out_dir: &Path) -> io::Result<Self> {
        let blob_dir = out_dir.join(BLOB_SUBDIR);
        // Start from scratch so blobs from earlier builds don't accumulate.
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

    /// Registers `bytes` under both its pretty URL path and its immutable digest path.
    fn add(&mut self, path: &Path, bytes: &[u8]) -> BuildResult<()> {
        let identity_digest = self.write_blob(bytes)?;
        let mut variants = vec![encoded_asset_literal("Identity", &identity_digest)];
        for coding in &COMPRESSED_CODINGS {
            let digest = self.write_blob(&(coding.encode)(bytes)?)?;
            variants.push(encoded_asset_literal(coding.encoding_variant, &digest));
        }

        let content_type = mime_guess::from_path(path).first_or_text_plain();
        let index = self.assets.len();
        self.assets.push(format!(
            r#"ConstAsset {{
                content_type: "{content_type}",
                variants: &[{}],
            }}"#,
            variants.join(",\n"),
        ));

        let pretty = translate_path(path);
        let digest = format!("{DIGEST_PREFIX}{identity_digest}{pretty}");
        let asset_ref = format!("&CONST_ASSETS[{index}]");
        self.map.entry(pretty.clone(), asset_ref.clone());
        self.map.entry(digest.clone(), asset_ref);
        self.digest_paths.insert(pretty, digest);

        Ok(())
    }

    /// Writes `bytes` to a file named after its SHA-256 digest and returns the digest.
    fn write_blob(&self, bytes: &[u8]) -> io::Result<String> {
        let digest = hex::encode(Sha256::digest(bytes));
        fs::write(self.blob_dir.join(&digest), bytes)?;
        Ok(digest)
    }

    /// Builds the template engine, with an `asset` helper that maps a pretty asset path to its
    /// cache-busting digest path.
    fn template_engine(&self) -> Handlebars<'static> {
        let digest_paths = self.digest_paths.clone();
        let mut handlebars = Handlebars::new();
        handlebars.set_strict_mode(true);
        handlebars.register_helper(
            "asset",
            Box::new(
                move |h: &Helper,
                      _: &Handlebars,
                      _: &Context,
                      _: &mut RenderContext,
                      out: &mut dyn Output|
                      -> HelperResult {
                    let param = h
                        .param(0)
                        .and_then(|v| v.value().as_str())
                        .ok_or(RenderErrorReason::ParamNotFoundForIndex("asset", 0))?;

                    let digest_path = digest_paths.get(param).ok_or_else(|| {
                        RenderErrorReason::Other(format!("unknown asset: {param}"))
                    })?;

                    out.write(digest_path)?;
                    Ok(())
                },
            ),
        );
        handlebars
    }

    fn write_to(&self, path: &Path) -> io::Result<()> {
        let mut out = BufWriter::new(File::create(path)?);
        writeln!(out, "const DIGEST_PREFIX: &str = {DIGEST_PREFIX:?};")?;
        writeln!(
            out,
            "static CONST_ASSETS: [ConstAsset; {}] = [{}];",
            self.assets.len(),
            self.assets.join(",\n"),
        )?;
        writeln!(
            out,
            r"
                #[allow(clippy::unreadable_literal)]
                static ASSET_MAP: phf::Map<&'static str, &'static ConstAsset> = {};
            ",
            self.map.build()
        )?;
        out.flush()
    }
}

fn encoded_asset_literal(encoding_variant: &str, blob_digest: &str) -> String {
    format!(
        r#"EncodedAsset {{
            encoding: Encoding::{encoding_variant},
            etag: "\"{blob_digest}\"",
            data: include_bytes!(concat!(env!("OUT_DIR"), "/{BLOB_SUBDIR}/{blob_digest}")),
        }}"#
    )
}

/// Maps an asset's path relative to its root directory to the URL path it is served under.
///
/// `index.html` files are served as their directory and other `.html` files without their
/// extension:
///
/// - `index.html` → `/`
/// - `blog/index.html` → `/blog/`
/// - `contact.html` → `/contact`
/// - `stylesheet.css` → `/stylesheet.css`
fn translate_path(path: &Path) -> String {
    let mut path_buf = PathBuf::from("/");

    path_buf.push(path);

    if path_buf
        .file_name()
        .is_some_and(|file_name| file_name.eq_ignore_ascii_case("index.html"))
    {
        // Replacing the file name with "" leaves the trailing slash.
        path_buf.set_file_name("");
    } else if path_buf
        .extension()
        .is_some_and(|extension| extension.eq_ignore_ascii_case("html"))
    {
        path_buf.set_extension("");
    }

    path_buf
        .into_string()
        .expect("asset paths must be valid UTF-8")
}

fn main() -> BuildResult<()> {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR")?);
    let out_dir = PathBuf::from(env::var("OUT_DIR")?);

    println!("cargo:rerun-if-env-changed=TARGETS_DIR");
    let mut asset_dirs = vec![manifest_dir.join("assets")];
    if let Ok(targets_dir) = env::var("TARGETS_DIR") {
        asset_dirs.push(PathBuf::from(targets_dir));
    }

    let mut table = AssetTable::new(&out_dir)?;
    let mut templates = Vec::new();

    for root in &asset_dirs {
        println!("cargo:rerun-if-changed={}", root.display());
        for entry in WalkDir::new(root) {
            let entry = entry?;
            if !entry.file_type().is_file() {
                continue;
            }

            let path = entry.path().strip_prefix(root)?;

            if path.extension().is_some_and(|ext| ext == "hbs") {
                templates.push((entry.path().to_path_buf(), path.with_extension("")));
                continue;
            }

            table.add(path, &fs::read(entry.path())?)?;
        }
    }

    // Templates are rendered after every static asset is registered so the `asset` helper
    // can resolve their digest paths. As a consequence, templates can't reference templates.
    let handlebars = table.template_engine();

    let turnstile_sitekey = if env::var_os("CARGO_CFG_DEBUG_ASSERTIONS").is_some() {
        // Cloudflare's always-pass test site key, paired with the test secret that
        // `contact::Config::default` uses under the same `debug_assertions` condition.
        "1x00000000000000000000BB"
    } else {
        "0x4AAAAAAACsmQqydNII05ly"
    };
    let template_data = HashMap::from([("turnstile_sitekey", turnstile_sitekey)]);

    for (template_path, path) in templates {
        let template = fs::read_to_string(&template_path)?;
        let rendered = handlebars.render_template(&template, &template_data)?;
        table.add(&path, rendered.as_bytes())?;
    }

    table.write_to(&out_dir.join("asset_table.rs"))?;

    Ok(())
}
