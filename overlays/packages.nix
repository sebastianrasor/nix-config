_: final: prev:
let
  inherit (prev) lib;
in
lib.pipe ../packages [
  builtins.readDir
  builtins.attrNames
  (builtins.filter (name: name != "default.nix"))
  (map (name: {
    name = lib.removeSuffix ".nix" name;
    value = final.callPackage ../packages/${name} { };
  }))
  builtins.listToAttrs
]
