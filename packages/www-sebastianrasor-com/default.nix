{ pkgs, ... }:
let
  cargoToml = fromTOML (builtins.readFile ./Cargo.toml);
in
pkgs.rustPlatform.buildRustPackage {
  inherit (cargoToml.package) version;
  pname = cargoToml.package.name;
  meta.mainProgram = cargoToml.package.name;
  buildInputs = [ pkgs.openssl ];
  nativeBuildInputs = [ pkgs.pkg-config ];
  src = pkgs.lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
