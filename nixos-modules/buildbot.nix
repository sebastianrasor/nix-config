{
  config,
  constants,
  inputs,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.buildbot;
in
{
  options.sebastianrasor.buildbot = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
}
// lib.optionalAttrs (inputs ? buildbot-nix) {
  imports = [
    inputs.buildbot-nix.nixosModules.buildbot-master
    inputs.buildbot-nix.nixosModules.buildbot-worker
  ];

  config = lib.mkIf cfg.enable {
    services.buildbot-nix = {
      master = {
        enable = true;
        domain = "buildbot.ts.${constants.domain}";
        workersFile = config.sops.templates."workers.json".path;
        admins = ["sebastian"];
        github = {
          appId = 3369053;
          appSecretKeyFile = config.sops.secrets."github/appClientSecrets/buildbot".path;
          webhookSecretFile = config.sops.secrets."buildbot/webhookSecret".path;
        };
        webhookBaseUrl = "https://buildbot.${constants.domain}/";
        authBackend = "oidc";
        oidc = {
          name = "Authentik";
          discoveryUrl = "https://authentik.${constants.domain}/application/o/buildbot/.well-known/openid-configuration";
          clientId = "l6g8dHF4VHNx7e58WJlBZZFlYPJvi9SukQZH0wvY";
          clientSecretFile = config.sops.secrets."oidc/clientSecrets/buildbot".path;
        };
      };

      worker = {
        enable = true;
        workerPasswordFile = config.sops.secrets."buildbot/workerPassword".path;
      };
    };

    sebastianrasor.reverse-proxy.proxies."buildbot" = "http://127.0.0.1:${toString config.services.buildbot-master.port}";

    sops = {
      secrets = {
        "buildbot/webhookSecret" = { };
        "buildbot/workerPassword" = { };
        "github/appClientSecrets/buildbot" = { };
        "oidc/clientSecrets/buildbot" = { };
      };
      templates."workers.json".content = ''
        [
          {
            "name": "localhost",
            "pass": "${config.sops.placeholder."buildbot/workerPassword"}",
            "cores": 24
          }
        ]
      '';
    };
  };
}
