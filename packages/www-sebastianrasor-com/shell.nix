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
    mailpit
    rust-analyzer
    rustfmt
  ];

  MP_SMTP_AUTH = "noreply:password1";
  MP_SMTP_AUTH_ALLOW_INSECURE = true;
}
