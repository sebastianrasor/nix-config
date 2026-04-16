inputs@{ nixpkgs, self, ... }:
let
  inherit (nixpkgs) lib;
in
lib.pipe ./. [
  builtins.readDir
  builtins.attrNames
  (builtins.filter (name: name != "default.nix"))
  (map (name: {
    name = lib.removeSuffix ".nix" name;
    value =
      let
        configurationModule = import ./${name} inputs;
      in
      lib.nixosSystem {
        specialArgs = {
          constants = import ../constants.nix;
        };
        modules = [ configurationModule ] ++ lib.attrsets.attrValues self.nixosModules;
      };
  }))
  builtins.listToAttrs
]
