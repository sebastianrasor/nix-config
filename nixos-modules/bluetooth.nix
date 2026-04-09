{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.bluetooth;
in
{
  options.sebastianrasor.bluetooth = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = lib.mkForce false;
    };

    sebastianrasor.persistence.directories = [ "/var/lib/bluetooth" ];
  };
}
