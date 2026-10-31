{
  constants,
  self,
  ...
}:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.reverse-proxy;
  acmeEnabled = config.sebastianrasor.acme.enable;
  acmeBaseDomain = config.sebastianrasor.acme.baseDomainName;
  proxyProtocolPort = 8443;

  hasPassthrough = cfg.passthroughHost != null && self ? nixosConfigurations.${cfg.passthroughHost};
  passthroughConfig = self.nixosConfigurations.${cfg.passthroughHost}.config;
  passthroughIp = lib.head (lib.splitString "/" passthroughConfig.sebastianrasor.wireguard.address);
  passthroughDomains = lib.optionals hasPassthrough (
    lib.pipe passthroughConfig.sebastianrasor.reverse-proxy.proxies [
      builtins.attrValues
      (lib.filter (p: p.public))
      (lib.concatMap (p: [ p.domain ] ++ p.aliases))
      (lib.filter (d: !lib.hasSuffix ".ts.${constants.domain}" d))
      lib.unique
    ]
  );

  hasPublicProxies = builtins.any (p: p.public) (builtins.attrValues cfg.proxies);

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

    passthroughHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

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
      commonHttpConfig = lib.optionalString (hasPublicProxies || hasPassthrough) ''
        real_ip_header proxy_protocol;
        set_real_ip_from 127.0.0.1;
        set_real_ip_from 10.100.0.0/24;
      '';
      streamConfig = lib.optionalString hasPassthrough ''
        map $ssl_preread_server_name $sni_upstream {
          ${lib.concatMapStringsSep "\n  " (
            domain: "${domain} ${passthroughIp}:${toString proxyProtocolPort};"
          ) passthroughDomains}
          default 127.0.0.1:${toString proxyProtocolPort};
        }

        server {
          listen 0.0.0.0:443;
          listen [::0]:443;
          ssl_preread on;
          proxy_protocol on;
          proxy_pass $sni_upstream;
        }
      '';
      virtualHosts =
        lib.optionalAttrs (hasPublicProxies || hasPassthrough) {
          "_" = {
            default = true;
            rejectSSL = true;
            listen = [
              {
                addr = if hasPassthrough then "127.0.0.1" else "0.0.0.0";
                port = proxyProtocolPort;
                ssl = true;
                proxyProtocol = true;
              }
            ];
            locations."/".return = "444";
          };
        }
        // lib.mapAttrs' (
          _: proxy:
          lib.nameValuePair proxy.domain {
            forceSSL = lib.mkForce acmeEnabled;
            useACMEHost = lib.mkIf acmeEnabled (lib.mkForce acmeBaseDomain);
            serverAliases = proxy.aliases;
            listen = lib.mkIf (hasPassthrough || proxy.public) (
              [
                {
                  addr = "0.0.0.0";
                  port = 80;
                }
                {
                  addr = "[::0]";
                  port = 80;
                }
                {
                  addr = if hasPassthrough then "127.0.0.1" else "0.0.0.0";
                  port = proxyProtocolPort;
                  ssl = true;
                  proxyProtocol = true;
                }
              ]
              ++ lib.optionals (!hasPassthrough) [
                {
                  addr = "0.0.0.0";
                  port = 443;
                  ssl = true;
                }
                {
                  addr = "[::0]";
                  port = 443;
                  ssl = true;
                }
              ]
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

    networking.hosts = lib.mkIf hasPassthrough {
      ${passthroughIp} = passthroughDomains;
    };

    sebastianrasor.acme = {
      inherit (config.services.nginx) group;
      extraDomainNames = lib.concatMap (proxy: [ proxy.domain ] ++ proxy.aliases) (
        builtins.attrValues cfg.proxies
      );
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      80
      443
    ];
  };
}
