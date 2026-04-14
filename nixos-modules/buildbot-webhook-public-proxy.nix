{
  config,
  constants,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.buildbot-webhook-public-proxy;
  acmeEnabled = config.sebastianrasor.acme.enable;
  acmeBaseDomain = config.sebastianrasor.acme.baseDomainName;
in
{
  options.sebastianrasor.buildbot-webhook-public-proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    sebastianrasor.reverse-proxy.proxies."buildbot" = "https://buildbot.ts.${constants.domain}";
    services.nginx.virtualHosts."buildbot.${constants.domain}" = {
      forceSSL = acmeEnabled;
      useACMEHost = lib.mkIf acmeEnabled acmeBaseDomain;
      locations."/change_hook/github" = {
        proxyPass = "https://buildbot.ts.${constants.domain}/change_hook/github";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_buffering off;
          proxy_pass_header Authorization;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          proxy_ssl_server_name on;
          send_timeout 600s;
        '';
      };
    };

    sebastianrasor.acme = {
      extraDomainNames = [ "buildbot.${constants.domain}" ];
    };
  };
}
