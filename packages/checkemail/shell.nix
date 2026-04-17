args@{
  pkgs ? import <nixpkgs> { },
}:
let
  pkg = import ./default.nix args;
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
