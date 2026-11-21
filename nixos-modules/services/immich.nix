{ constants, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.immich;
in
{
  options.sebastianrasor.immich = {
    enable = lib.mkEnableOption "Immich";
  };

  config = lib.mkIf cfg.enable {
    services = {
      immich = {
        accelerationDevices = null;
        enable = true;

        mediaLocation = "/srv/immich";
      };

      immich-public-proxy = {
        enable = true;
        port = 3001;
        immichUrl = "http://[::1]:${toString config.services.immich.port}";
      };
    };

    users.users.immich.extraGroups = [
      "video"
      "render"
    ];

    fileSystems = {
      "/srv/immich/backups" = {
        device = "/media/immich/backups";
        fsType = "none";
        options = [ "bind" ];
      };
      "/srv/immich/upload" = {
        device = "/media/immich/upload";
        fsType = "none";
        options = [ "bind" ];
      };
    };

    sebastianrasor = {
      reverse-proxy.proxies = {
        "immich" = {
          target = "http://[::1]:${toString config.services.immich.port}";
          maxBodySize = "50000m";
          proxyBuffering = false;
          timeout = "600s";
        };
        "immich.${constants.domain}" = {
          public = true;
          target = "http://127.0.0.1:${toString config.services.immich-public-proxy.port}";
          proxyBuffering = false;
          timeout = "600s";
        };
      };

      unas.mounts."Immich" = "/media/immich";
    };

    sebastianrasor.persistence.directories = [
      "/srv/immich/encoded-video"
      "/srv/immich/library"
      "/srv/immich/profile"
      "/srv/immich/thumbs"
    ];

    systemd.services.immich.unitConfig.RequiresMountsFor = [
      "/srv/immich/backups"
      "/srv/immich/encoded-video"
      "/srv/immich/library"
      "/srv/immich/profile"
      "/srv/immich/thumbs"
      "/srv/immich/upload"
    ];
  };
}
