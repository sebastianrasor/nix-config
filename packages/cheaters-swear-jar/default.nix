{
  lib,
  craneLib,
  openssl,
  pkg-config,
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
in
craneLib.buildPackage (
  commonArgs
  // {
    cargoArtifacts = craneLib.buildDepsOnly commonArgs;
    meta = {
      mainProgram = (craneLib.crateNameFromCargoToml { inherit src; }).pname;
      platforms = [ "x86_64-linux" ];
    };
  }
)
