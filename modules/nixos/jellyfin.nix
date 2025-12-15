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

    users.users.jellyfin.extraGroups = lib.mkIf config.sebastianrasor.unas.enable [ "unifi-drive-nfs" ];

    fileSystems."${config.services.jellyfin.dataDir}/data/backups" =
      lib.mkIf config.sebastianrasor.unas.enable
        {
          device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Jellyfin";
          fsType = "nfs";
        };

    fileSystems."/media/movies" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Movies";
      fsType = "nfs";
      options = [
        "nolock"
        "ro"
      ];
    };

    fileSystems."/media/shows" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Shows";
      fsType = "nfs";
      options = [
        "nolock"
        "ro"
      ];
    };

    services.nginx.virtualHosts."jellyfin.${config.sebastianrasor.domain}" = {
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

    # Need to transcode on disk since tmpfs root usually doesn't have the space for transcodes
    sebastianrasor.persistence.directories = [
      config.services.jellyfin.dataDir
      "${config.services.jellyfin.cacheDir}/transcodes"
    ];
  };
}
