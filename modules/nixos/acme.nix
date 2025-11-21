{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.acme.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.acme.enable {
    sops.secrets.acme-env = lib.mkIf config.sebastianrasor.secrets.enable { };
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
  };
}
