{
  config,
  lib,
  pkgs,
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

    baseDomainName = lib.mkOption {
      type = lib.types.str;
      default = "${config.networking.hostName}.${config.sebastianrasor.domain}";
    };

    extraDomainNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "acme";
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
      certs.${cfg.baseDomainName} = {
        inherit (cfg) extraDomainNames group;
        postRun = ''
          ${pkgs.acl}/bin/setfacl -m \
            u:nginx:rx \
            /var/lib/acme/${cfg.baseDomainName}

          ${pkgs.acl}/bin/setfacl -m \
            u:nginx:r \
            /var/lib/acme/${cfg.baseDomainName}/*.pem
        '';
      };
    };

    sebastianrasor.persistence.directories = [ "/var/lib/acme" ];

    sops.secrets.acme-env = lib.mkIf config.sebastianrasor.secrets.enable { };
  };
}
