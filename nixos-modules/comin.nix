{ comin, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.comin;
in
{
  options.sebastianrasor.comin = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  imports = [
    comin.nixosModules.comin
  ];

  config = lib.mkIf cfg.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/sebastianrasor/nix-config";
          branches = {
            main.name = "main";
            testing.name = "";
          };
        }
      ];
    };
  };
}
