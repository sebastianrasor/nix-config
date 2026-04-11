pkgs:
pkgs.lib.pipe ./. [
  builtins.readDir
  builtins.attrNames
  (builtins.filter (name: name != "default.nix"))
  (map (name: {
    name = pkgs.lib.removeSuffix ".nix" name;
    value = pkgs.callPackage ./${name} { };
  }))
  builtins.listToAttrs
]
