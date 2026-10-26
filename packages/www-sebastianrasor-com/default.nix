{
  lib,
  callPackage,
  openssl,
  pkg-config,
  rustPlatform,
  targets ? callPackage ../targets { },
}:
let
  cargoToml = fromTOML (builtins.readFile ./Cargo.toml);
in
rustPlatform.buildRustPackage {
  inherit (cargoToml.package) version;
  pname = cargoToml.package.name;
  buildInputs = [ openssl ];
  nativeBuildInputs = [ pkg-config ];
  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;
  postPatch = ''
    install -Dm644 -t assets/ ${targets}/*.pdf
  '';
  meta = {
    inherit (targets.meta) platforms;
    mainProgram = cargoToml.package.name;
  };
}
