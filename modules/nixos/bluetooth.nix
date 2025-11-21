{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.bluetooth.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      # not a fan of always-on bluetooth
      powerOnBoot = lib.mkForce false;
    };
    sebastianrasor.persistence.directories = [ "/var/lib/bluetooth" ];
  };
}
