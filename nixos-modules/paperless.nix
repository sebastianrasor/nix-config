_:
{
  config,
  constants,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.paperless;
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
  };

  config = lib.mkIf cfg.enable {
    services.paperless = {
      enable = true;
      database.createLocally = true;
      domain = "paperless.ts.${constants.domain}";
      environmentFile = config.sops.templates."paperless.env".path;
      settings = {
        PAPERLESS_ENABLE_ALLAUTH = true;
        PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
        PAPERLESS_AUTO_LOGIN = true;
        PAPERLESS_AUTO_CREATE = true;
        PAPERLESS_LOGOUT_REDIRECT_URL = "https://authentik.${constants.domain}/application/o/paperless/end-session/";
      };
    };

    sops = {
      secrets."oidc/clientSecrets/paperless" = { };
      templates."paperless.env".content = ''
        PAPERLESS_SOCIALACCOUNT_PROVIDERS=${
          builtins.toJSON {
            "openid_connect" = {
              "APPS" = [
                {
                  "provider_id" = "authentik";
                  "name" = "authentik";
                  "client_id" = "mEHjbCfj26egw2cZ1IJPQs9coBJbOCYw0j7hDPOd";
                  "secret" = config.sops.placeholder."oidc/clientSecrets/paperless";
                  "settings" = {
                    "server_url" =
                      "https://authentik.${constants.domain}/application/o/paperless/.well-known/openid-configuration";
                    "claims"."username" = "email";
                  };
                }
              ];
              "OAUTH_PKCE_ENABLED" = "True";
            };
          }
        }
      '';
    };

    sebastianrasor.persistence.directories = [
      {
        inherit (config.services.paperless) user;
        directory = config.services.paperless.dataDir;
      }
    ];

    sebastianrasor.reverse-proxy.proxies."paperless" =
      "http://127.0.0.1:${toString config.services.paperless.port}";
  };
}
