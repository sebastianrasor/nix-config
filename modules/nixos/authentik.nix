{
  config,
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

  config = lib.mkIf cfg.enable {
    services.authentik = {
      enable = true;
      environmentFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.authentik-env.path;
      nginx = {
        enable = true;
        host = "authentik.ts.${config.sebastianrasor.domain}";
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
      serverAliases = [ "authentik.${config.sebastianrasor.domain}" ];
    };

    sebastianrasor.acme.extraDomainNames = [
      "authentik.${config.sebastianrasor.domain}"
      "authentik.ts.${config.sebastianrasor.domain}"
    ];

    sops.secrets.authentik-env = lib.mkIf config.sebastianrasor.secrets.enable { };
  };
}
