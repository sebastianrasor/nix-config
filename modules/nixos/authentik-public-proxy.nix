{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.authentik-public-proxy.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.authentik-public-proxy.enable {
    services.nginx.virtualHosts."authentik.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "https://$carbon";
        extraConfig = ''
          resolver 100.100.100.100;
          set $carbon "carbon.ts.${config.sebastianrasor.domain}";
        '';
        proxyWebsockets = true;
      };
    };
  };
}
