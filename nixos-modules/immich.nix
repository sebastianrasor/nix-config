_:
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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.immich = {
      accelerationDevices = null;
      enable = true;

      mediaLocation = "/srv/immich";
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
      reverse-proxy.proxies."immich" = "http://[::1]:${toString config.services.immich.port}";

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
