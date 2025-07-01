{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.headscale.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.headscale.enable {
    services.headscale = {
      enable = true;
      settings = {
        server_url = "https://headscale.${config.sebastianrasor.domain}:443";
        dns.magic_dns = false;
        dns.override_local_dns = false;
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
