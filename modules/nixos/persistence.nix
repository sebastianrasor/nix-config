{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.persistence.enable = lib.mkEnableOption "";
    sebastianrasor.persistence.storagePath = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist";
    };
  };

  config = lib.mkIf config.sebastianrasor.persistence.enable {
    # This is actually required for home-manager impermanence module:
    # https://github.com/nix-community/impermanence/blob/4b3e914cdf97a5b536a889e939fb2fd2b043a170/README.org#home-manager
    programs.fuse.userAllowOther = true;

    environment.persistence."${config.sebastianrasor.persistence.storagePath}" = {
      hideMounts = true;
      directories = [
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
