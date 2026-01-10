{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.paperless;
  secretsEnabled = config.sebastianrasor.secrets.enable;

  socialAccountProviders =
    if secretsEnabled then
      {
        "openid_connect" = {
          "APPS" = [
            {
              "provider_id" = "authentik";
              "name" = "authentik";
              "client_id" = cfg.oidcClientId;
              "secret" = cfg.oidcSecret;
              "settings" = {
                "server_url" =
                  "https://authentik.${config.sebastianrasor.domain}/application/o/paperless/.well-known/openid-configuration";
                "claims"."username" = "email";
              };
            }
          ];
          "OAUTH_PKCE_ENABLED" = "True";
        };
      }
    else
      null;
  environmentFile =
    if secretsEnabled then
      pkgs.writeText "paperlessEnvironment" ''
        PAPERLESS_SOCIALACCOUNT_PROVIDERS=${builtins.toJSON socialAccountProviders}
      ''
    else
      null;
in
{
  options.sebastianrasor.paperless = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    oidc = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    oidcClientId = lib.mkOption {
      type = lib.types.str;
      default = "mEHjbCfj26egw2cZ1IJPQs9coBJbOCYw0j7hDPOd";
    };

    oidcSecret = lib.mkOption {
      type = lib.types.str;
      default = config.sops.placeholder.paperless-openid-client-secret;
    };
  };

  config = lib.mkIf cfg.enable {
    services.paperless = {
      enable = true;
      database.createLocally = true;
      domain = "paperless.ts.${config.sebastianrasor.domain}";
      environmentFile = lib.mkIf secretsEnabled config.sops.templates."paperless/environment".path;
      settings = {
        PAPERLESS_ENABLE_ALLAUTH = lib.mkIf cfg.oidc true;
        PAPERLESS_APPS = lib.mkIf cfg.oidc "allauth.socialaccount.providers.openid_connect";
        PAPERLESS_AUTO_LOGIN = lib.mkIf cfg.oidc true;
        PAPERLESS_AUTO_CREATE = lib.mkIf cfg.oidc true;
        PAPERLESS_LOGOUT_REDIRECT_URL = lib.mkIf cfg.oidc "https://authentik.${config.sebastianrasor.domain}/application/o/paperless/end-session/";
      };
    };

    sops = lib.mkIf secretsEnabled {
      secrets.paperless-openid-client-secret = { };
      templates."paperless/environment".file = lib.mkIf secretsEnabled environmentFile;
    };

    sebastianrasor.persistence.directories = [
      {
        directory = config.services.paperless.dataDir;
        user = config.services.paperless.user;
      }
    ];

    sebastianrasor.reverse-proxy.proxies."paperless" =
      "http://127.0.0.1:${toString config.services.paperless.port}";
  };
}
