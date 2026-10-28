inputs@{ nixpkgs, ... }:
let
  repoLib = import ../lib { inherit (nixpkgs) lib; };
in
repoLib.readModulesDir ./. inputs
