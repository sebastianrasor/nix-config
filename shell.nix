{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    age
    age-plugin-yubikey
    age-plugin-tpm
    fd
    jujutsu
    nh
    nixd
    nixf
    nixfmt
    package-version-server
    sops
    statix
  ];
  shellHook = ''
    export NH_FLAKE=".";
  '';
}
