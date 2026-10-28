{ constants, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.forgejo;
in
{
  options.sebastianrasor.forgejo = {
    enable = lib.mkEnableOption "Forgejo";
  };

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      package = pkgs.forgejo;
      database.type = "postgres";
      dump.enable = true;
      lfs.enable = true;
      settings = {
        oauth2_client.ENABLE_AUTO_REGISTRATION = true;

        server = {
          DOMAIN = "forgejo.ts.${constants.domain}";
          ROOT_URL = "https://forgejo.ts.${constants.domain}";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = 3000;
        };

        services.DISABLE_REGISTRATION = true;

        webhook = {
          ALLOWED_HOST_LIST = "nixbot.ts.${constants.domain}";
        };
      };
    };

    systemd.services.forgejo.after = [ "authentik.service" ];

    sebastianrasor = {
      persistence.directories = [ config.services.forgejo.stateDir ];

      reverse-proxy.proxies."forgejo" =
        "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}";

      unas.mounts."Forgejo" = config.services.forgejo.dump.backupDir;
    };
  };
}
