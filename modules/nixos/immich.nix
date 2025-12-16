{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.immich.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.immich.enable {
    services.immich = {
      accelerationDevices = null;
      enable = true;
    };

    users.users.immich.extraGroups = [
      "video"
      "render"
    ];

    sebastianrasor.persistence.directories = [ config.services.immich.mediaLocation ];

    sebastianrasor.unas.mounts."Immich" = "/srv/immich";

    fileSystems."/var/lib/immich/backups" = {
      device = "/srv/immich/backups";
      fsType = "none";
      options = [
        "bind"
      ];
    };

    fileSystems."/var/lib/immich/library" = {
      device = "/srv/immich/library";
      fsType = "none";
      options = [
        "bind"
      ];
    };

    fileSystems."/var/lib/immich/profile" = {
      device = "/srv/immich/profile";
      fsType = "none";
      options = [
        "bind"
      ];
    };

    fileSystems."/var/lib/immich/upload" = {
      device = "/srv/immich/upload";
      fsType = "none";
      options = [
        "bind"
      ];
    };

    systemd.services.immich.unitConfig.RequiresMountsFor = [
      "/var/lib/immich/backups"
      "/var/lib/immich/library"
      "/var/lib/immich/profile"
      "/var/lib/immich/upload"
    ];

    services.nginx.virtualHosts."immich.ts.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://[::1]:${toString config.services.immich.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
      };
    };
  };
}
