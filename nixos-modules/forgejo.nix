_:
{
  config,
  constants,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.forgejo;
in
{
  options.sebastianrasor.forgejo = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      database.type = "postgres";
      dump.enable = true;
      lfs.enable = true;
      settings = {
        actions.ENABLED = false;

        oath2_client.ENABLE_AUTO_REGISTRATION = true;

        server = {
          DOMAIN = "forgejo.ts.${constants.domain}";
          ROOT_URL = "https://forgejo.ts.${constants.domain}";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = 3000;
        };

        services.DISABLE_REGISTRATION = true;
      };
    };

    sebastianrasor = {
      persistence.directories = [ config.services.forgejo.stateDir ];

      reverse-proxy.proxies."forgejo" =
        "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}";

      unas.mounts."Forgejo" = config.services.forgejo.dump.backupDir;
    };
  };
}
