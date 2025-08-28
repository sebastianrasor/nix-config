{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.google-chrome.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.google-chrome.enable {
    home.packages = [pkgs.google-chrome];
    home.persistence."${config.sebastianrasor.persistence.storagePath}".directories = lib.mkIf config.sebastianrasor.persistence.enable (builtins.map (lib.strings.removePrefix config.home.homeDirectory) ["${config.xdg.configHome}/google-chrome"]);
  };
}
