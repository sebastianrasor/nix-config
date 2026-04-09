{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShellNoCC {
  nativeBuildInputs = with pkgs; [
    fd
    git
    nh
    nixd
    nixf
    nixfmt
  ];
  shellHook = ''
    export NH_FLAKE=".";
  '';
}
