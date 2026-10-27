{
  pkgs ? import <nixpkgs> { },
}:
let
  pkg = pkgs.callPackage ./default.nix { };
in
pkgs.craneLib.devShell {
  inputsFrom = [
    pkg
  ];

  packages = with pkgs; [
    bacon
    mailpit
    rust-analyzer
  ];

  MP_SMTP_AUTH = "noreply:password1";
  MP_SMTP_AUTH_ALLOW_INSECURE = true;
}
