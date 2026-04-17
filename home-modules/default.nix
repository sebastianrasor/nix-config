inputs@{ nixpkgs, ... }:
let
  inherit (nixpkgs) lib;
in
lib.pipe ./. [
  builtins.readDir
  builtins.attrNames
  (builtins.filter (name: name != "default.nix"))
  (map (name: {
    name = lib.removeSuffix ".nix" name;
    value = lib.modules.importApply ./${name} inputs;
  }))
  builtins.listToAttrs
]
