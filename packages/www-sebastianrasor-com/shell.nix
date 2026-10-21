{
  pkgs ? import <nixpkgs> { },
}:
let
  pkg = pkgs.callPackage ./default.nix { };
in
pkgs.mkShell {
  inherit (pkg) TARGETS_DIR;

  inputsFrom = [
    pkg
  ];

  packages = with pkgs; [
    bacon
    cargo
    clippy
    rust-analyzer
    rustfmt
  ];
}
