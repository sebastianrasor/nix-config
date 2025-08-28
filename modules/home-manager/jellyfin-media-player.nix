{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.jellyfin-media-player.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.jellyfin-media-player.enable {
    home.packages = [pkgs.jellyfin-media-player];
    home.persistence."${config.sebastianrasor.persistence.storagePath}".directories = lib.mkIf config.sebastianrasor.persistence.enable (builtins.map (lib.strings.removePrefix config.home.homeDirectory) ["${config.xdg.dataHome}/Jellyfin Media Player"]);
  };
}
