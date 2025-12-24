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
    };

    users.users.immich.extraGroups = [
      "video"
      "render"
    ];

    sebastianrasor.persistence.directories = [ config.services.immich.mediaLocation ];

    sebastianrasor.reverse-proxy.proxies."immich" =
      "http://[::1]:${toString config.services.immich.port}";

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
  };
}
