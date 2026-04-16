{ self, ... }:
{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    self.formatter.${pkgs.stdenv.hostPlatform.system}

    age
    age-plugin-yubikey
    age-plugin-tpm
    fd
    jujutsu
    nh
    nixd
    nixf
    sops
  ];
  shellHook = ''
    export NH_FLAKE=".";
  '';
}
