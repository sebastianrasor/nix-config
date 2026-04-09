{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.jellyfin-media-player;
in
{
  options.sebastianrasor.jellyfin-media-player = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      jellyfin-media-player
    ];
  };
}
