{
  pkgs ? import <nixpkgs> { },
}:
let
  pkg = pkgs.callPackage ./default.nix { };
in
pkgs.mkShell {
  inputsFrom = [
    pkg
  ];

  packages = with pkgs; [
    bacon
    cargo
    clippy
    rust-analyzer
  ];
}
