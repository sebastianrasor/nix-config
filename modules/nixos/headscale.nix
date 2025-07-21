{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.headscale.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.headscale.enable {
    sops.secrets.headscale-openid-client-secret = lib.mkIf config.sebastianrasor.secrets.enable {
      owner = config.systemd.services.headscale.serviceConfig.User;
    };
    networking.firewall.allowedUDPPorts = [3478];
    services.headscale = {
      enable = true;
      settings = {
        server_url = "https://headscale.${config.sebastianrasor.domain}:443";
        oidc = lib.mkIf config.sebastianrasor.secrets.enable {
          only_start_if_oidc_is_available = false;
          issuer = "https://authentik.rasor.us/application/o/headscale/";
          client_id = "t5tdQYkn2zReh1DCHhTwMNiZnSIq5nvLMjsT13nQ";
          client_secret_path = config.sops.secrets.headscale-openid-client-secret.path;
        };
        derp.urls = [];
        derp.server = {
          enabled = true;
          stun_listen_addr = "0.0.0.0:3478";
          region_id = 999;
          region_code = "headscale";
          region_name = "Headscale Embedded DERP";
        };
        dns = {
          magic_dns = true;
          base_domain = "rasor.us";
          override_local_dns = false;
          extra_records = [
            {
              name = "actual.rasor.us";
              type = "A";
              value = "100.64.0.3";
            }
            {
              name = "authentik.rasor.us";
              type = "A";
              value = "100.64.0.3";
            }
            {
              name = "frigate.rasor.us";
              type = "A";
              value = "100.64.0.3";
            }
            {
              name = "headscale.rasor.us";
              type = "A";
              value = "137.220.49.126";
            }
            {
              name = "homeassistant.rasor.us";
              type = "A";
              value = "100.64.0.6";
            }
            {
              name = "homebox.rasor.us";
              type = "A";
              value = "100.64.0.3";
            }
            {
              name = "immich.rasor.us";
              type = "A";
              value = "100.64.0.3";
            }
            {
              name = "jellyfin.rasor.us";
              type = "A";
              value = "100.64.0.3";
            }
            {
              name = "radicale.rasor.us";
              type = "A";
              value = "100.64.0.3";
            }
          ];
        };
      };
    };

    services.nginx.virtualHosts."headscale.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
        proxyWebsockets = true;
        extraConfig = "proxy_ssl_server_name on;" + "proxy_pass_header Authorization;" + "proxy_buffering off;";
      };
    };
  };
}
