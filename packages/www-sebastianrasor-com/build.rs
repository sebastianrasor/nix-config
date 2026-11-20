use std::{
    collections::{BTreeMap, HashMap},
    env,
    error::Error,
    fs,
    io::{self, Read},
    mem,
    os::unix::fs::PermissionsExt,
    path::{Component, Path, PathBuf},
    sync::Mutex,
};

use brotli::CompressorReader;
use flate2::{
    Compression,
    read::{GzEncoder, ZlibEncoder},
};
use handlebars::{
    Context, Handlebars, Helper, HelperResult, JsonValue, Output, PathAndJson, RenderContext,
    RenderErrorReason, to_json,
};
use sha2::{Digest, Sha256};
use walkdir::WalkDir;

const DEFAULT_ASSETS_DIR: &str = "assets";
const DEFAULT_HOME_DIR: &str = "home";
const DIGEST_PREFIX: &str = "/by-digest/";

const EAGER_TEXT_MAX_BYTES: usize = 4096;
const S_IFDIR_0755: u32 = 0o040_755;
const S_IFREG_0644: u32 = 0o100_644;
const S_IFREG_0755: u32 = 0o100_755;

const DIRECT_MEDIA_EXTS: &[&str] = &[
    "pdf", "svg", "svgz", "png", "jpg", "jpeg", "gif", "webp", "avif", "ico", "bmp", "mp3", "ogg",
    "wav", "flac", "mp4", "webm", "woff", "woff2", "ttf", "otf", "zip", "gz", "tgz", "bz2", "xz",
    "zst", "tar", "7z", "wasm", "bin", "iso", "img",
];

const BROTLI_BUFFER_SIZE: usize = 4096;
const BROTLI_QUALITY: u32 = 11;
const BROTLI_LGWIN: u32 = 24;
const ZSTD_COMPRESSION_LEVEL: i32 = 19;

struct HomeRoute {
    canonical_path: String,
    aliases: Vec<String>,
    initial_command: String,
}

enum Fs9pNode {
    Dir(BTreeMap<String, Self>),
    File {
        size: usize,
        mode: u32,
        rel_digest_url: String,
    },
}

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

    fn add(
        &mut self,
        base_dir: &Path,
        path: &Path,
        bytes: &[u8],
        headers: &[(String, String)],
    ) -> io::Result<String> {
        let url_path = url_path(base_dir, path);
        let content_type = mime_guess::from_path(path).first_or_text_plain();
        self.add_url(
            &url_path,
            &[],
            content_type.as_ref(),
            bytes,
            is_precompressed(path),
            headers,
        )
    }

    fn add_url(
        &mut self,
        url_path: &str,
        aliases: &[String],
        content_type: &str,
        bytes: &[u8],
        precompressed: bool,
        headers: &[(String, String)],
    ) -> io::Result<String> {
        let (asset_ref, digest_path) =
            self.push_asset(url_path, content_type, bytes, precompressed, headers)?;
        self.map.entry(url_path.to_owned(), asset_ref.clone());
        for alias in aliases {
            self.map.entry(alias.clone(), asset_ref.clone());
        }
        self.map.entry(digest_path.clone(), asset_ref);
        self.digest_paths
            .insert(url_path.to_owned(), digest_path.clone());
        Ok(digest_path)
    }

    fn add_digest_only(
        &mut self,
        url_path: &str,
        content_type: &str,
        bytes: &[u8],
        precompressed: bool,
    ) -> io::Result<String> {
        let (asset_ref, digest_path) =
            self.push_asset(url_path, content_type, bytes, precompressed, &[])?;
        self.map.entry(digest_path.clone(), asset_ref);
        Ok(digest_path)
    }

    fn push_asset(
        &mut self,
        url_path: &str,
        content_type: &str,
        bytes: &[u8],
        precompressed: bool,
        headers: &[(String, String)],
    ) -> io::Result<(String, String)> {
        let identity = self.write_blob(bytes)?;
        let compressed = if precompressed {
            Vec::new()
        } else {
            self.write_compressed(bytes)?.into()
        };

        let asset_ref = format!("&CONST_ASSETS[{}]", self.assets.len());
        self.assets
            .push(const_asset(content_type, &identity, &compressed, headers));
        let digest_path = format!("{DIGEST_PREFIX}{identity}{url_path}");
        Ok((asset_ref, digest_path))
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

fn is_precompressed(path: &Path) -> bool {
    path.extension()
        .and_then(|ext| ext.to_str())
        .is_some_and(|ext| {
            matches!(
                ext.to_ascii_lowercase().as_str(),
                "woff"
                    | "woff2"
                    | "img"
                    | "png"
                    | "jpg"
                    | "jpeg"
                    | "gif"
                    | "webp"
                    | "avif"
                    | "mp3"
                    | "ogg"
                    | "flac"
                    | "mp4"
                    | "webm"
                    | "zip"
                    | "gz"
                    | "tgz"
                    | "bz2"
                    | "xz"
                    | "zst"
                    | "7z"
            )
        })
        || path.file_name().is_some_and(|name| name == "bzImage")
}

fn is_terminal_text(path: &Path, bytes: &[u8]) -> bool {
    let ext_is_media = path
        .extension()
        .and_then(|ext| ext.to_str())
        .is_some_and(|ext| {
            DIRECT_MEDIA_EXTS
                .iter()
                .any(|media| ext.eq_ignore_ascii_case(media))
        });
    !ext_is_media && !bytes.contains(&0) && std::str::from_utf8(bytes).is_ok()
}

fn file_mode(path: &Path) -> io::Result<u32> {
    let mode = fs::metadata(path)?.permissions().mode();
    Ok(if mode & 0o111 != 0 {
        S_IFREG_0755
    } else {
        S_IFREG_0644
    })
}

fn insert_fs9p_file(
    root: &mut BTreeMap<String, Fs9pNode>,
    rel_path: &str,
    size: usize,
    mode: u32,
    digest_path: &str,
) {
    let rel_digest_url = digest_path
        .strip_prefix('/')
        .expect("digest path must start with /")
        .to_owned();
    let mut parts = rel_path.split('/').peekable();
    let mut current = root;
    while let Some(part) = parts.next() {
        if parts.peek().is_some() {
            current = match current
                .entry(part.to_owned())
                .or_insert_with(|| Fs9pNode::Dir(BTreeMap::new()))
            {
                Fs9pNode::Dir(children) => children,
                Fs9pNode::File { .. } => panic!("conflicting file and directory at {rel_path}"),
            };
        } else {
            current.insert(
                part.to_owned(),
                Fs9pNode::File {
                    size,
                    mode,
                    rel_digest_url,
                },
            );
            return;
        }
    }
}

fn fs9p_children_json(children: &BTreeMap<String, Fs9pNode>) -> Vec<JsonValue> {
    children
        .iter()
        .map(|(name, node)| match node {
            Fs9pNode::Dir(sub) => to_json((
                name,
                0_usize,
                0_u32,
                S_IFDIR_0755,
                0_u32,
                0_u32,
                fs9p_children_json(sub),
            )),
            Fs9pNode::File {
                size,
                mode,
                rel_digest_url,
            } => to_json((name, *size, 0_u32, *mode, 0_u32, 0_u32, rel_digest_url)),
        })
        .collect()
}

fn const_asset(
    content_type: &str,
    identity: &str,
    compressed: &[(&str, String)],
    headers: &[(String, String)],
) -> String {
    let compressed = compressed
        .iter()
        .map(|(encoding, digest)| encoded_asset(encoding, digest))
        .collect::<Vec<_>>()
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

fn relative_slash_path(base_dir: &Path, path: &Path) -> String {
    path.strip_prefix(base_dir)
        .expect("path must be within base directory")
        .components()
        .filter_map(|component| match component {
            Component::Normal(part) => Some(part.to_str().expect("paths must be valid UTF-8")),
            _ => None,
        })
        .collect::<Vec<_>>()
        .join("/")
}

fn url_path(base_dir: &Path, path: &Path) -> String {
    let path = relative_slash_path(base_dir, path);
    let path = match path.strip_suffix("index.html") {
        Some(dir) if dir.is_empty() || dir.ends_with('/') => dir,
        _ => path.strip_suffix(".html").unwrap_or(&path),
    };
    format!("/{path}")
}

fn shell_quote(arg: &str) -> String {
    if !arg.is_empty()
        && !arg.starts_with('-')
        && arg
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || matches!(b, b'/' | b'.' | b'_' | b'-'))
    {
        arg.to_owned()
    } else {
        format!("'{}'", arg.replace('\'', "'\\''"))
    }
}

fn load_static_assets(
    assets_dir: &Path,
    table: &mut AssetTable,
) -> Result<(Option<PathBuf>, Vec<PathBuf>), Box<dyn Error>> {
    let mut asset_files = Vec::new();
    for entry in WalkDir::new(assets_dir) {
        let entry = entry?;
        if entry.file_type().is_file() {
            asset_files.push(entry.into_path());
        }
    }
    asset_files.sort();

    let mut index_template = None;
    let mut templates = Vec::new();
    for path in asset_files {
        if path.extension().is_some_and(|ext| ext == "hbs") {
            if path
                .file_name()
                .is_some_and(|name| name == "index.html.hbs")
            {
                index_template = Some(path);
            } else {
                templates.push(path);
            }
        } else {
            table.add(assets_dir, &path, &fs::read(&path)?, &[])?;
        }
    }

    Ok((index_template, templates))
}

fn discover_home(
    home_dir: &Path,
    table: &mut AssetTable,
) -> Result<(Vec<HomeRoute>, String), Box<dyn Error>> {
    let mut entries = Vec::new();
    for entry in WalkDir::new(home_dir) {
        let entry = entry?;
        let is_dir = entry.file_type().is_dir();
        if !is_dir && !entry.file_type().is_file() {
            continue;
        }
        let path = entry.into_path();
        let rel = relative_slash_path(home_dir, &path);
        entries.push((rel, path, is_dir));
    }
    entries.sort_by(|a, b| a.0.cmp(&b.0));

    let mut routes = Vec::new();
    let mut fs9p_root = BTreeMap::new();
    let mut fs9p_size = 0_usize;

    for (rel, path, is_dir) in entries {
        if is_dir {
            let canonical_path = if rel.is_empty() {
                "/".to_owned()
            } else {
                format!("/{rel}")
            };
            let readme_path = path.join("README");
            let has_text_readme =
                readme_path.is_file() && is_terminal_text(&readme_path, &fs::read(&readme_path)?);
            let (initial_command, aliases) = if has_text_readme {
                let readme_rel = if rel.is_empty() {
                    "README".to_owned()
                } else {
                    format!("{rel}/README")
                };
                (
                    format!("cat {}", shell_quote(&readme_rel)),
                    vec![format!("/{readme_rel}")],
                )
            } else if rel.is_empty() {
                ("ls".to_owned(), Vec::new())
            } else {
                (format!("ls {}", shell_quote(&rel)), Vec::new())
            };
            routes.push(HomeRoute {
                canonical_path,
                aliases,
                initial_command,
            });
            continue;
        }

        let bytes = fs::read(&path)?;
        let mode = file_mode(&path)?;
        let url = format!("/{rel}");

        if is_terminal_text(&path, &bytes) {
            if bytes.len() >= EAGER_TEXT_MAX_BYTES {
                let digest_path =
                    table.add_digest_only(&url, "text/plain; charset=utf-8", &bytes, false)?;
                fs9p_size += bytes.len();
                insert_fs9p_file(&mut fs9p_root, &rel, bytes.len(), mode, &digest_path);
            }
            if path.file_name().is_none_or(|name| name != "README") {
                routes.push(HomeRoute {
                    canonical_path: url,
                    aliases: Vec::new(),
                    initial_command: format!("cat {}", shell_quote(&rel)),
                });
            }
        } else {
            let content_type = mime_guess::from_path(&path).first_or_octet_stream();
            let digest_path = table.add_url(
                &url,
                &[],
                content_type.as_ref(),
                &bytes,
                is_precompressed(&path),
                &[],
            )?;
            fs9p_size += bytes.len();
            insert_fs9p_file(&mut fs9p_root, &rel, bytes.len(), mode, &digest_path);
        }
    }

    let home_fs_json = to_json(HashMap::from([
        ("version", to_json(3_u32)),
        ("size", to_json(fs9p_size)),
        ("fsroot", to_json(fs9p_children_json(&fs9p_root))),
    ]))
    .to_string();

    Ok((routes, home_fs_json))
}

fn main() -> Result<(), Box<dyn Error>> {
    println!("cargo::rerun-if-env-changed=WWW_ASSETS_DIR");
    println!("cargo::rerun-if-env-changed=WWW_HOME_DIR");

    let assets_dir = env::var_os("WWW_ASSETS_DIR")
        .map_or_else(|| PathBuf::from(DEFAULT_ASSETS_DIR), PathBuf::from);
    let home_dir =
        env::var_os("WWW_HOME_DIR").map_or_else(|| PathBuf::from(DEFAULT_HOME_DIR), PathBuf::from);

    println!("cargo::rerun-if-changed={}", assets_dir.display());
    println!("cargo::rerun-if-changed={}", home_dir.display());

    let mut table = AssetTable::new(PathBuf::from(env::var("OUT_DIR")?));
    let (index_template, templates) = load_static_assets(&assets_dir, &mut table)?;
    let (home_routes, home_fs_json) = discover_home(&home_dir, &mut table)?;

    let template_headers = Mutex::new(Vec::new());
    let mut handlebars = Handlebars::new();
    handlebars.set_strict_mode(env::var_os("CARGO_CFG_DEBUG_ASSERTIONS").is_none());
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
                template_headers
                    .lock()
                    .unwrap()
                    .push((name, params.collect()));
                Ok(())
            },
        ),
    );

    if let Some(index_path) = index_template {
        let index_src = fs::read_to_string(&index_path)?;
        let html_mime = mime_guess::from_path("index.html").first_or_text_plain();
        let assets_json = to_json(&table.digest_paths);
        let home_fs_val = to_json(home_fs_json);

        for route in &home_routes {
            let template_data = HashMap::from([
                ("assets", assets_json.clone()),
                ("canonical_path", to_json(&route.canonical_path)),
                ("initial_command", to_json(&route.initial_command)),
                ("home_fs", home_fs_val.clone()),
            ]);
            let rendered = handlebars.render_template(&index_src, &template_data)?;
            let headers = mem::take(&mut *template_headers.lock().unwrap());
            table.add_url(
                &route.canonical_path,
                &route.aliases,
                html_mime.as_ref(),
                rendered.as_bytes(),
                false,
                &headers,
            )?;
        }
    }

    let canonical_routes: Vec<&str> = home_routes
        .iter()
        .map(|route| route.canonical_path.as_str())
        .collect();
    let template_data = HashMap::from([
        ("assets", to_json(&table.digest_paths)),
        ("routes", to_json(canonical_routes)),
    ]);
    for path in templates {
        let rendered = handlebars.render_template(&fs::read_to_string(&path)?, &template_data)?;
        let headers = mem::take(&mut *template_headers.lock().unwrap());
        table.add(
            &assets_dir,
            &path.with_extension(""),
            rendered.as_bytes(),
            &headers,
        )?;
    }

    table.write()?;

    Ok(())
}
