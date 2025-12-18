{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.postgresql;
in
{
  options.sebastianrasor.postgresql = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql.enable = true;

    sebastianrasor.persistence.directories = [ config.services.postgresql.dataDir ];
  };
}
