_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.jellyfin;
in
{
  options.sebastianrasor.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin";
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      package = lib.mkIf config.sebastianrasor.intel-arc-a380.enable (
        pkgs.jellyfin.override {
          jellyfin-ffmpeg = pkgs.jellyfin-ffmpeg.override {
            ffmpeg_8-full = pkgs.ffmpeg_8-full.override {
              withMfx = false;
              withVpl = true;
              withUnfree = true;
            };
          };
        }
      );
    };

    systemd.services.jellyfin.unitConfig.RequiresMountsFor = [
      "/media/movies"
      "/media/music"
      "/media/shows"
    ];

    sebastianrasor = {
      reverse-proxy.proxies."jellyfin" = "http://127.0.0.1:8096";

      # Need to transcode on disk since tmpfs root usually doesn't have the space for transcodes
      persistence.directories = [
        config.services.jellyfin.dataDir
        "${config.services.jellyfin.cacheDir}/transcodes"
      ];

      unas.mounts = {
        "Jellyfin" = "${config.services.jellyfin.dataDir}/data/backups";
        "Movies" = "/media/movies";
        "Music" = "/media/music";
        "Shows" = "/media/shows";
      };
    };
  };
}
