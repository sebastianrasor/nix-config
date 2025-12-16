{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.postgresql.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.postgresql.enable {
    services.postgresql.enable = true;

    sebastianrasor.persistence.directories = [ config.services.postgresql.dataDir ];
  };
}
