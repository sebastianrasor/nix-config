{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.unas.enable = lib.mkEnableOption "";

    sebastianrasor.unas.host = lib.mkOption {
      type = lib.types.str;
    };

    sebastianrasor.unas.basePath = lib.mkOption {
      type = lib.types.str;
      default = "/var/nfs/shared";
    };
  };

  config = lib.mkIf config.sebastianrasor.unas.enable {
    users.groups = {
      unifi-drive-nfs = {
        gid = 988;
      };
    };
  };
}
