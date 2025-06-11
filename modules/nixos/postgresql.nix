{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.postgresql.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.postgresql.enable {
    #users.users.postgres.extraGroups = lib.mkIf config.sebastianrasor.unas.enable ["unifi-drive-nfs"];
    fileSystems."/media/postgresql" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/PostgreSQL";
      fsType = "nfs";
    };
    systemd.services.postgresql = lib.mkIf config.sebastianrasor.unas.enable {
      environment = {
        PGDATABASE = "postgres";
        PGUSER = "postgres";
      };
      serviceConfig = {
        User = lib.mkForce "unifi-drive-nfs";
        Group = lib.mkForce "unifi-drive";
      };
    };
    services.postgresql = {
      enable = true;
      dataDir = lib.mkIf config.sebastianrasor.unas.enable "/media/postgresql";
      identMap = ''
        postgres unifi-drive-nfs postgres
      '';
    };
  };
}
