{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.unas;
in
{
  options.sebastianrasor.unas = {
    enable = lib.mkEnableOption "";

    host = lib.mkOption {
      type = lib.types.str;
      default = "unas-pro.internal";
    };

    basePath = lib.mkOption {
      type = lib.types.str;
      default = "/var/nfs/shared";
    };

    mounts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.unifi-drive.gid = 988;
    users.users.unifi-drive-nfs = {
      group = "unifi-drive";
      isSystemUser = true;
      uid = 977;
    };

    fileSystems = lib.mapAttrs' (
      shareName: mountPath:
      lib.nameValuePair mountPath {
        device = "${cfg.host}:${cfg.basePath}/${shareName}";
        fsType = "nfs";
      }
    ) cfg.mounts;
  };
}
