{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.steam;
in
{
  options.sebastianrasor.steam = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv = {
          STEAM_FORCE_DESKTOPUI_SCALING = 2;
        };
      };
    };
  };
}
