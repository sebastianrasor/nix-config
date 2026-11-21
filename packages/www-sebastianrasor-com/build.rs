use std::{
    env,
    path::{Path, PathBuf},
};

fn main() {
    println!("cargo::rerun-if-env-changed=WWW_ASSETS_DIR");
    let is_release = env::var_os("CARGO_CFG_DEBUG_ASSERTIONS").is_none();
    let assets_dir = env::var_os("WWW_ASSETS_DIR").map_or_else(
        || {
            assert!(
                !is_release,
                "Release builds require WWW_ASSETS_DIR (use `nix build` or enter the Nix devShell)"
            );
            Path::new(env!("CARGO_MANIFEST_DIR")).join("assets")
        },
        PathBuf::from,
    );
    memory_serve::load_directory_with_embed(assets_dir, is_release);
}
