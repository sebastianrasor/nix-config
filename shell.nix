{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    fd
    jujutsu
    nh
    nixd
    nixf
    nixfmt
  ];
  shellHook = ''
    export NH_FLAKE=".";
  '';
}
