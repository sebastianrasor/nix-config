{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.postgresql.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.postgresql.enable {
    users.users.postgres.extraGroups = lib.mkIf config.sebastianrasor.unas.enable ["unifi-drive-nfs"];
    users.users.postgres = {
      isSystemUser = true;
      uid = lib.mkForce 977;
    };
    fileSystems."/media/postgresql" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/PostgreSQL";
      fsType = "nfs";
    };
    services.postgresql = {
      enable = true;
      dataDir = lib.mkIf config.sebastianrasor.unas.enable "/media/postgresql";
    };
  };
}
