{
  config,
  constants,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.home-manager;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.sebastianrasor.home-manager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      home-manager
    ];
    home-manager = {
      backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit constants inputs outputs;
      };
      sharedModules = lib.attrsets.attrValues outputs.homeModules;
    };
  };
}
