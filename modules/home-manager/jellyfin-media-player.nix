# https://github.com/nixos/nixpkgs/issues/437865
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.jellyfin-media-player.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.jellyfin-media-player.enable {
    home.packages = [ pkgs.jellyfin-media-player ];
    sebastianrasor.persistence.directories = [ "${config.xdg.dataHome}/Jellyfin Media Player" ];
  };
}
