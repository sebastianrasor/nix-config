{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.homebox.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.homebox.enable {
    services.homebox = {
      enable = true;
      database.createLocally = true;
    };

    services.nginx.virtualHosts."homebox.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:7745";
        proxyWebsockets = true;
        extraConfig = "proxy_ssl_server_name on;" + "proxy_pass_header Authorization;";
      };
    };
  };
}
