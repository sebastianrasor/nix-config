_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.reverse-proxy;
  acmeEnabled = config.sebastianrasor.acme.enable;
  acmeBaseDomain = config.sebastianrasor.acme.baseDomainName;
  localWgIp = lib.head (lib.splitString "/" config.sebastianrasor.wireguard.address);

  publicDomains = lib.pipe cfg.proxies [
    builtins.attrValues
    (lib.filter (p: p.public))
    (lib.concatMap (p: [ p.domain ] ++ p.aliases))
    lib.unique
  ];
  hasPublicProxies = publicDomains != [ ];

  proxySubmodule = lib.types.submodule (
    { name, ... }:
    {
      options = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = if lib.hasInfix "." name then name else "${name}.${cfg.baseDomainName}";
        };

        target = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };

        aliases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };

        public = lib.mkEnableOption "exposing this proxy publicly";
      };
    }
  );
in
{
  options.sebastianrasor.reverse-proxy = {
    enable = lib.mkEnableOption "reverse proxy";

    baseDomainName = lib.mkOption {
      type = lib.types.str;
    };

    openFirewall = lib.mkEnableOption "opening firewall ports for the reverse proxy";

    proxies = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.coercedTo lib.types.str (target: { inherit target; }) proxySubmodule
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      proxyResolveWhileRunning = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      resolver.addresses = [ "127.0.0.53:53" ];
      virtualHosts =
        lib.optionalAttrs hasPublicProxies {
          "_" = {
            default = true;
            rejectSSL = true;
            listenAddresses = [ localWgIp ];
            locations."/".return = "444";
          };
        }
        // lib.mapAttrs' (
          _: proxy:
          lib.nameValuePair proxy.domain {
            forceSSL = lib.mkForce acmeEnabled;
            useACMEHost = lib.mkIf acmeEnabled (lib.mkForce acmeBaseDomain);
            serverAliases = proxy.aliases;
            listenAddresses = lib.mkIf proxy.public (
              config.services.nginx.defaultListenAddresses ++ [ localWgIp ]
            );
            locations = lib.mkIf (proxy.target != null) {
              "/" = {
                proxyPass = lib.mkForce proxy.target;
                proxyWebsockets = lib.mkForce true;
                extraConfig = lib.mkForce ''
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
          }
        ) cfg.proxies;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      80
      443
    ];

    sebastianrasor = {
      acme = {
        inherit (config.services.nginx) group;
        extraDomainNames = lib.concatMap (proxy: [ proxy.domain ] ++ proxy.aliases) (
          builtins.attrValues cfg.proxies
        );
      };

      wireguard = lib.mkIf hasPublicProxies {
        domains = publicDomains;
        forwardPorts = [
          {
            port = 80;
            proto = "tcp";
          }
          {
            port = 443;
            proto = "tcp";
          }
        ];
      };
    };
  };
}
