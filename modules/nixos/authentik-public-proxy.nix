{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.authentik-public-proxy;
in
{
  options.sebastianrasor.authentik-public-proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."authentik.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "https://$carbon";
        extraConfig = ''
          resolver 100.100.100.100;
          set $carbon "authentik.ts.${config.sebastianrasor.domain}";
        '';
        proxyWebsockets = true;
      };
    };
  };
}
