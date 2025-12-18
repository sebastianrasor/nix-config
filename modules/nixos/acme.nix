{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.acme;
in
{
  options.sebastianrasor.acme = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults = {
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        email = "general@rasor.us";
        environmentFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.acme-env.path;
      };
    };

    sebastianrasor.persistence.directories = [ "/var/lib/acme" ];

    sops.secrets.acme-env = lib.mkIf config.sebastianrasor.secrets.enable { };
  };
}
