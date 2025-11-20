{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.bolt.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.bolt.enable {
    services.hardware.bolt.enable = true;
    environment.persistence."${config.sebastianrasor.persistence.storagePath}".directories =
      lib.mkIf config.sebastianrasor.persistence.enable
        [ "/var/lib/boltd" ];
  };
}
