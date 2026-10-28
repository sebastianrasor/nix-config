{
  pkgs ? import <nixpkgs> { },
}:
pkgs.craneLib.devShell {
  inputsFrom = [
    pkgs.cheaters-swear-jar
  ];

  packages = with pkgs; [
    rust-analyzer
  ];
}
