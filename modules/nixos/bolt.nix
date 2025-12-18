{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.bolt;
in
{
  options.sebastianrasor.bolt = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.hardware.bolt.enable = true;

    sebastianrasor.persistence.directories = [ "/var/lib/boltd" ];
  };
}
