{
  lib,
  openssl,
  pkg-config,
  rustPlatform,
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
  meta = {
    mainProgram = cargoToml.package.name;
    platforms = [ "x86_64-linux" ];
  };
}
