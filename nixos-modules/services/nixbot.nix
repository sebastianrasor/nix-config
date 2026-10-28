{ constants, nixbot, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.nixbot;
in
{
  options.sebastianrasor.nixbot = {
    enable = lib.mkEnableOption "nixbot";
  };

  imports = [
    nixbot.nixosModules.nixbot
  ];

  config = lib.mkIf cfg.enable {
    services.nixbot = {
      enable = true;
      nginx.enable = false;
      useHTTPS = true;
      domain = "nixbot.ts.${constants.domain}";
      admins = [ "oidc:Authentik:sebastian" ];
      gitea = {
        enable = true;
        instanceUrl = "https://forgejo.ts.${constants.domain}";

        tokenFile = config.sops.secrets."forgejo/accessTokens/nixbot".path;
      };
      oidc = {
        enable = true;
        name = "Authentik";
        discoveryUrl = "https://authentik.${constants.domain}/application/o/nixbot/.well-known/openid-configuration";
        clientId = "l6g8dHF4VHNx7e58WJlBZZFlYPJvi9SukQZH0wvY";
        clientSecretFile = config.sops.secrets."oidc/clientSecrets/nixbot".path;
      };
      effects.perRepoSecretFiles."gitea:sebastian/nix-config" =
        config.sops.templates."nixbot/secrets.json".path;
    };

    systemd.services.nixbot = {
      after = [ "authentik.service" ];
      restartIfChanged = false;
    };

    sebastianrasor.reverse-proxy.proxies."nixbot" = {
      target = "http://127.0.0.1:${toString config.services.nixbot.port}";
      aliases = [ "nixbot.${constants.domain}" ];
    };

    sops = {
      secrets = {
        "forgejo/accessTokens/nixbot" = { };
        "oidc/clientSecrets/nixbot" = { };
        "ssh/privateKeys/deploy" = { };
      };
      templates = {
        "nixbot/secrets.json".content = ''
          {
            "ssh": {
              "kind": "Secret",
              "data": {
                "privateKey": "${config.sops.placeholder."ssh/privateKeys/deploy"}",
                "publicKey": "${constants.deploySshPublicKey}"
              },
              "condition": "isDefaultBranch"
            }
          }
        '';
      };
    };
  };
}
