_:
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
    enable = lib.mkEnableOption "PostgreSQL";

    backup.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.postgresql.enable = true;

      sebastianrasor.persistence.directories = [ config.services.postgresql.dataDir ];
    })
    (lib.mkIf cfg.backup.enable {
      services.postgresqlBackup.enable = true;

      sebastianrasor.unas.mounts."PostgreSQL" = config.services.postgresqlBackup.location;
    })
  ];
}
