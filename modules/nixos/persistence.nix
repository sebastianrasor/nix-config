{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.persistence.enable = lib.mkEnableOption "";
    sebastianrasor.persistence.storagePath = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist";
    };
  };

  config = lib.mkIf config.sebastianrasor.persistence.enable {
    environment.persistence."${config.sebastianrasor.persistence.storagePath}" = {
      hideMounts = true;
      directories = [
        "/home"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/log"
      ];
      files = [
        "/etc/machine-id"
      ];
    };
  };
}
