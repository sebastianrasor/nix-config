{
  constants,
  self,
  ...
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.headscale;
  carbonProxyDomains = lib.optionals (self ? nixosConfigurations.carbon) (
    map (p: p.domain) (
      builtins.attrValues self.nixosConfigurations.carbon.config.sebastianrasor.reverse-proxy.proxies
    )
  );
  extraCarbonDomains = map (subdomain: "${subdomain}.ts.${constants.domain}") [
    "deploy"
    "frigate"
    "hydra"
    "ollama"
    "open-webui"
  ];
in
{
  options.sebastianrasor.headscale = {
    enable = lib.mkEnableOption "Headscale";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."oidc/clientSecrets/headscale" = lib.mkIf config.sebastianrasor.secrets.enable {
      owner = config.systemd.services.headscale.serviceConfig.User;
    };
    networking.firewall.allowedUDPPorts = [ 3478 ];
    systemd.services.headscale-oidc-restart = {
      after = [ "headscale.service" ];
      wantedBy = [ "headscale.service" ];
      serviceConfig.ExecStart = pkgs.writeShellScript "headscale-oidc-restart" ''
        STATUS_CODE="$(${lib.getExe pkgs.curl} -o /dev/null --silent --write-out "%{http_code}" "${config.services.headscale.settings.server_url}/oidc/callback")"

        if [ "$STATUS_CODE" = "400" ]; then
          exit 0
        fi

        until ${lib.getExe pkgs.curl} -o /dev/null -s "${config.services.headscale.settings.oidc.issuer}/.well-known/openid-configuration"
        do
          sleep 30
        done

        systemctl restart headscale.service
      '';
    };
    services.headscale = {
      enable = true;
      settings = {
        server_url = "https://headscale.${constants.domain}";
        oidc = lib.mkIf config.sebastianrasor.secrets.enable {
          only_start_if_oidc_is_available = false;
          issuer = "https://authentik.${constants.domain}/application/o/headscale/";
          client_id = "t5tdQYkn2zReh1DCHhTwMNiZnSIq5nvLMjsT13nQ";
          client_secret_path = config.sops.secrets."oidc/clientSecrets/headscale".path;
        };
        derp.urls = [ ];
        derp.server = {
          enabled = true;
          verify_clients = true;
          stun_listen_addr = "0.0.0.0:3478";
          region_id = 999;
          region_code = "headscale";
          region_name = "Headscale Embedded DERP";
        };
        dns = {
          magic_dns = true;
          # https://github.com/juanfont/headscale/blob/3123d5286bbeb1d4958cec3c92d5a0969b201a9b/hscontrol/types/config_test.go#L414
          base_domain = "ts.${constants.domain}";
          override_local_dns = false;
          # eventually I'd like to set these to CNAMES to the magic dns records
          # for the respective nodes on the tailnet. that's not currently
          # possible, though. :(
          extra_records =
            map (name: {
              inherit name;
              type = "A";
              value = "100.64.0.3";
            }) (lib.unique (carbonProxyDomains ++ extraCarbonDomains))
            ++ [
              {
                name = "homeassistant.ts.${constants.domain}";
                type = "A";
                value = "100.64.0.6";
              }
            ];
        };
      };
    };

    sebastianrasor.persistence.directories = [ "/var/lib/headscale" ];

    sebastianrasor.reverse-proxy.proxies."headscale" =
      "http://127.0.0.1:${toString config.services.headscale.port}";
  };
}
