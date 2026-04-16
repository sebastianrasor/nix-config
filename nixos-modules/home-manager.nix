{ home-manager, self, ... }:
{
  config,
  constants,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.home-manager;
in
{
  options.sebastianrasor.home-manager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  imports = [
    home-manager.nixosModules.home-manager
  ];

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.home-manager
    ];
    home-manager = {
      backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit constants;
      };
      sharedModules = lib.attrsets.attrValues self.homeModules;
    };
  };
}
