inputs@{ nixpkgs, self, ... }:
let
  inherit (nixpkgs) lib;
  repoLib = import ../lib { inherit lib; };
in
repoLib.readNixDir ./. (
  path:
  lib.nixosSystem {
    modules = [ (lib.modules.importApply path inputs) ] ++ lib.attrsets.attrValues self.nixosModules;
  }
)
