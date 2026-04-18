pkgs:
let
  inherit (pkgs) lib;
in 
lib.pipe ./. [
  builtins.readDir
  builtins.attrNames
  (builtins.filter (name: name != "default.nix"))
  (map (name: {
    name = lib.removeSuffix ".nix" name;
    value = pkgs.callPackage ./${name} { };
  }))
  builtins.listToAttrs
  (lib.filterAttrs (_: lib.meta.availableOn { inherit (pkgs.stdenv.hostPlatform) system; }))
]
