{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.jellyfin;
in
{
  options.sebastianrasor.jellyfin = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin.enable = true;

    sebastianrasor.reverse-proxy.proxies."jellyfin" = "http://127.0.0.1:8096";

    # Need to transcode on disk since tmpfs root usually doesn't have the space for transcodes
    sebastianrasor.persistence.directories = [
      config.services.jellyfin.dataDir
      "${config.services.jellyfin.cacheDir}/transcodes"
    ];

    sebastianrasor.unas.mounts = {
      "Jellyfin" = "${config.services.jellyfin.dataDir}/data/backups";
      "Movies" = "/media/movies";
      "Shows" = "/media/shows";
    };

    systemd.services.immich.unitConfig.RequiresMountsFor = [
      "/media/movies"
      "/media/shows"
    ];
  };
}
