{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.immich-public-proxy;
in
{
  options.sebastianrasor.immich-public-proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.immich-public-proxy = {
      enable = true;
      port = 3001;
      immichUrl = "https://immich.ts.${config.sebastianrasor.domain}";
    };

    services.nginx.virtualHosts."immich.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.immich-public-proxy.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
      };
    };
  };
}
