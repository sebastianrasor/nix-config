let
  flake = builtins.getFlake (toString ./.);
in
(flake.inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit (flake) inputs; };
  check = false;
  modules = builtins.attrValues (flake.outputs.nixosModules or { });
}).options
