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

    sebastianrasor = {
      reverse-proxy.proxies."immich" = "http://[::1]:${toString config.services.immich.port}";

      unas.mounts."Immich" = "/srv/immich";
    };

    systemd.services.immich.unitConfig.RequiresMountsFor = [
      "/srv/immich"
    ];
  };
}
