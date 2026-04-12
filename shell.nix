{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    fd
    git
    nh
    nixd
    nixf
    nixfmt
  ];
  shellHook = ''
    export NH_FLAKE=".";

    git config core.hooksPath .githooks
  '';
}
