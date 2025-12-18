{
  config,
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

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      home-manager
    ];
    home-manager.backupFileExtension = "backup";
  };
}
