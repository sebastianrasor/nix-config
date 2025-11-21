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
    sebastianrasor.persistence.directories = [ "/var/lib/boltd" ];
  };
}
