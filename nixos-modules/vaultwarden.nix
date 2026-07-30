{ constants, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.vaultwarden;
in
{
  options.sebastianrasor.vaultwarden = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = {
        ROCKET_PORT = 8222;
        SSO_ENABLED = true;
        SSO_ONLY = true;
        SSO_AUTHORITY = "https://authentik.rasor.us/application/o/vaultwarden/";
        SSO_CLIENT_ID = "6CajPGwvVDreu3HQZvepITXdxFGGAxJK3ltaHuNJ";
      };
      configurePostgres = true;
      domain = "vaultwarden.ts.${constants.domain}";
      environmentFile = config.sops.templates."vaultwarden.env".path;
    };

    sops = {
      secrets = {
        "oidc/clientSecrets/vaultwarden" = { };
        "vaultwarden/adminToken" = { };
      };
      templates."vaultwarden.env".content = ''
        ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/adminToken"}
        SSO_CLIENT_SECRET=${config.sops.placeholder."oidc/clientSecrets/vaultwarden"}
      '';
    };

    sebastianrasor = {
      persistence.directories = [ "/var/lib/vaultwarden" ];
      reverse-proxy.proxies."vaultwarden" =
        "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };
  };
}
