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
    environment.persistence."${config.sebastianrasor.persistence.storagePath}".directories =
      lib.mkIf config.sebastianrasor.persistence.enable
        [ "/var/lib/bluetooth" ];
    hardware.bluetooth = {
      enable = true;
      # not a fan of always-on bluetooth
      powerOnBoot = lib.mkForce false;
    };
  };
}
