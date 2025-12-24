{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.reverse-proxy;
  acmeEnabled = config.sebastianrasor.acme.enable;
  acmeBaseDomain = config.sebastianrasor.acme.baseDomainName;
in
{
  options.sebastianrasor.reverse-proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    baseDomainName = lib.mkOption {
      type = lib.types.str;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    proxies = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      apply = lib.mapAttrs' (source: target: lib.nameValuePair "${source}.${cfg.baseDomainName}" target);
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      proxyResolveWhileRunning = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      resolver.addresses = [ "127.0.0.53:53" ];
      virtualHosts = lib.mapAttrs' (
        source: target:
        lib.nameValuePair source {
          forceSSL = acmeEnabled;
          useACMEHost = lib.mkIf acmeEnabled acmeBaseDomain;
          locations."/" = {
            proxyPass = target;
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
        }
      ) cfg.proxies;
    };

    sebastianrasor.acme = {
      extraDomainNames = builtins.attrNames cfg.proxies;
      group = config.services.nginx.group;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      80
      443
    ];
  };
}
