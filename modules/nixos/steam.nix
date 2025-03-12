{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.steam.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.steam.enable {
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
