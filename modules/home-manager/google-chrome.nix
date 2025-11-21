{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.google-chrome.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.google-chrome.enable {
    home.packages = [ pkgs.google-chrome ];
    sebastianrasor.persistence.directories = [ "${config.xdg.configHome}/google-chrome" ];
  };
}
