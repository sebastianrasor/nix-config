{ pkgs, ... }:
let
  cargoToml = fromTOML (builtins.readFile ./Cargo.toml);
in
pkgs.rustPlatform.buildRustPackage {
  pname = cargoToml.package.name;
  version = cargoToml.package.version;
  meta.mainProgram = cargoToml.package.name;
  buildInputs = [ pkgs.openssl ];
  nativeBuildInputs = [ pkgs.pkg-config ];
  src = pkgs.lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
