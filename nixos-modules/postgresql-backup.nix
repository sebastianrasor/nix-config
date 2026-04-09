{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.postgresql-backup;
in
{
  options.sebastianrasor.postgresql-backup = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.sebastianrasor.postgresql.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresqlBackup.enable = true;

    sebastianrasor.unas.mounts."PostgreSQL" = config.services.postgresqlBackup.location;
  };
}
