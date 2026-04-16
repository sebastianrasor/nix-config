let
  flake = builtins.getFlake (toString ./.);
  pkgs = import flake.inputs.nixpkgs { };
in
(flake.inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  check = false;
  modules = [
    {
      home = {
        homeDirectory = "/home/sebastian";
        username = "sebastian";
        stateVersion =
          pkgs.lib.lists.last
            (import (flake.inputs.home-manager.outPath + "/modules/misc/version.nix") {
              config = { };
              inherit (pkgs) lib;
            }).options.home.stateVersion.type.functor.payload.values;
      };
    }
  ]
  ++ builtins.attrValues (flake.outputs.homeModules or { });
}).options
