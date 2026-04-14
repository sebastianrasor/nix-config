{
  config,
  constants,
  inputs,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.authentik;
  acmeEnabled = config.sebastianrasor.acme.enable;
  acmeBaseDomain = config.sebastianrasor.acme.baseDomainName;
in
{
  options.sebastianrasor.authentik = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
}
// lib.optionalAttrs (inputs ? authentik-nix) {
  imports = [
    inputs.authentik-nix.nixosModules.default
  ];

  config = lib.mkIf cfg.enable {
    services.authentik = {
      enable = true;
      environmentFile = config.sops.templates."authentik.env".path;
      nginx = {
        enable = true;
        host = "authentik.ts.${constants.domain}";
      };
      settings = {
        disable_startup_analytics = true;
        avatars = "initials";
      };
    };

    # special circumstances for proxy from external to tailnet
    services.nginx.virtualHosts.${config.services.authentik.nginx.host} = {
      forceSSL = lib.mkForce acmeEnabled;
      useACMEHost = lib.mkIf acmeEnabled acmeBaseDomain;
      serverAliases = [ "authentik.${constants.domain}" ];
    };

    sebastianrasor.acme.extraDomainNames = [
      "authentik.${constants.domain}"
      "authentik.ts.${constants.domain}"
    ];

    sops = {
      secrets."authentik/secretKey" = { };
      templates."authentik.env".content = ''
        AUTHENTIK_SECRET_KEY=${config.sops.placeholder."authentik/secretKey"}
      '';
    };
  };
}
