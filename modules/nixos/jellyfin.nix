{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.jellyfin.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.jellyfin.enable {
    services.jellyfin.enable = true;

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

    services.nginx.virtualHosts."jellyfin.ts.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
        extraConfig =
          "proxy_ssl_server_name on;" + "proxy_pass_header Authorization;" + "proxy_buffering off;";
      };
    };
  };
}
