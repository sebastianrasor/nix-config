{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.jellyfin.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.jellyfin.enable {
    services.jellyfin = {
      enable = true;
      logDir = lib.mkIf config.sebastianrasor.unas.enable "/media/jellyfin/log";
      dataDir = lib.mkIf config.sebastianrasor.unas.enable "/media/jellyfin";
      configDir = lib.mkIf config.sebastianrasor.unas.enable "/media/jellyfin/config";
    };

    users.users.jellyfin.extraGroups = lib.mkIf config.sebastianrasor.unas.enable ["unifi-drive-nfs"];

    systemd.services.jellyfin.bindsTo = lib.mkIf config.sebastianrasor.unas.enable [
      "media-jellyfin.mount"
      "media-movies.mount"
      "media-shows.mount"
    ];
    systemd.services.jellyfin.unitConfig.RequiresMountsFor = lib.mkIf config.sebastianrasor.unas.enable [
      "/media/jellyfin"
      "/media/movies"
      "/media/shows"
    ];
    fileSystems."/media/jellyfin" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Jellyfin";
      fsType = "nfs";
      options = ["nolock"];
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
        extraConfig = "proxy_ssl_server_name on;" + "proxy_pass_header Authorization;" + "proxy_buffering off;";
      };
    };
  };
}
