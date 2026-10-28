inputs@{ nixpkgs, ... }:
let
  repoLib = import ../lib { inherit (nixpkgs) lib; };
in
repoLib.readNixDir ./. (path: import path inputs)
