self:
let
  inherit (self.inputs.nixpkgs) lib;
in
lib.pipe ./. [
  builtins.readDir
  builtins.attrNames
  (builtins.filter (name: name != "default.nix"))
  (map (name: {
    name = lib.removeSuffix ".nix" name;
    value = import ./${name};
  }))
  builtins.listToAttrs
]
