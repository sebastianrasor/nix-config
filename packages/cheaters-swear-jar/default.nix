{
  lib,
  cargo,
  craneLib,
  openssl,
  pkg-config,
  rustc,
  writeShellApplication,
}:
let
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      (craneLib.fileset.commonCargoSources ./.)
      ./src
    ];
  };
  commonArgs = {
    inherit src;
    strictDeps = true;
    buildInputs = [ openssl ];
    nativeBuildInputs = [ pkg-config ];
  };
  updateScript = writeShellApplication {
    name = "update-cheaters-swear-jar";
    runtimeInputs = [
      cargo
      rustc
    ];
    text = ''
      manifest="packages/cheaters-swear-jar/Cargo.toml"
      if [ ! -f "$manifest" ]; then
        echo "Run from the repository root containing $manifest" >&2
        exit 1
      fi

      cargo update --manifest-path "$manifest"
    '';
  };
in
craneLib.buildPackage (
  commonArgs
  // {
    cargoArtifacts = craneLib.buildDepsOnly commonArgs;
    passthru = {
      inherit updateScript;
    };
    meta = {
      mainProgram = (craneLib.crateNameFromCargoToml { inherit src; }).pname;
      platforms = [ "x86_64-linux" ];
    };
  }
)
