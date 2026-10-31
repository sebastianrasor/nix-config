{ constants, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.tranquil-pds;
in
{
  options.sebastianrasor.tranquil-pds = {
    enable = lib.mkEnableOption "Tranquil PDS";
  };

  config = lib.mkIf cfg.enable {
    services = {
      nginx.virtualHosts."sebastianrasor.com".locations = {
        "= /.well-known/atproto-did" = {
          extraConfig = ''
            default_type text/plain;
            add_header Access-Control-Allow-Origin *;
          '';
          return = ''200 "did:web:sebastianrasor.com"'';
        };
        "= /.well-known/did.json" = {
          alias = ./did.json;
          extraConfig = ''
            add_header Access-Control-Allow-Origin *;
          '';
        };
        "/".return = "301 https://www.sebastianrasor.com$request_uri";
      };

      tranquil-pds = {
        enable = true;
        database.createLocally = true;
        environmentFiles = [ config.sops.templates."tranquil-pds.env".path ];
        settings = {
          server = {
            hostname = "tranquil.${constants.domain}";
            port = 3002;
            allow_private_fetch = true;
            invite_code_required = true;
            disable_account_verification_gate = true;
          };
          sso.oidc = {
            client_id = "sFglPtSStjbfjQMtxFXH4N3K5pcGEnNrqPyjt8OP";
            display_name = "authentik";
            issuer = "https://authentik.${constants.domain}/application/o/tranquil-pds/";
          };
        };
      };
    };

    systemd.services.tranquil-pds = {
      after = [ "authentik.service" ];
      unitConfig.RequiresMountsFor = [ config.services.tranquil-pds.dataDir ];
      serviceConfig = {
        StateDirectory = lib.mkForce [
          "tranquil-pds"
          "tranquil-pds/blobs"
          "tranquil-pds/store"
        ];
        ReadWritePaths = lib.mkForce [ ];
      };
    };

    sops = {
      secrets = {
        "oidc/clientSecrets/tranquil-pds" = { };
        "tranquil-pds/dpopSecret" = { };
        "tranquil-pds/jwtSecret" = { };
        "tranquil-pds/masterKey" = { };
      };
      templates."tranquil-pds.env".content = ''
        DPOP_SECRET=${config.sops.placeholder."tranquil-pds/dpopSecret"}
        JWT_SECRET=${config.sops.placeholder."tranquil-pds/jwtSecret"}
        MASTER_KEY=${config.sops.placeholder."tranquil-pds/masterKey"}
        SSO_OIDC_CLIENT_SECRET=${config.sops.placeholder."oidc/clientSecrets/tranquil-pds"}
        SSO_OIDC_ENABLED=true
      '';
    };

    sebastianrasor = {
      persistence.directories = [
        {
          directory = config.services.tranquil-pds.dataDir;
          inherit (config.services.tranquil-pds) user group;
          mode = "0750";
        }
      ];

      reverse-proxy.proxies = {
        "sebastianrasor.com".public = true;
        "tranquil.${constants.domain}" = {
          public = true;
          target = "http://127.0.0.1:${toString config.services.tranquil-pds.settings.server.port}";
        };
      };
    };
  };
}
