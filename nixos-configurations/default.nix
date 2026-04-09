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
    value = lib.nixosSystem {
      specialArgs = {
        inherit (self) inputs outputs;
        constants = import ../constants.nix;
      };
      modules = [ ./${name} ] ++ lib.attrsets.attrValues self.outputs.nixosModules;
    };
  }))
  builtins.listToAttrs
]
