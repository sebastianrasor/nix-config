{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.actual.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.actual.enable {
    services.actual = {
      enable = true;
      settings = {
        loginMethod = "openid";
        allowedLoginMethods = [ "openid" ];
      };
    };

    # I really can't be bothered to try to figure out the best way to persist
    # the individual StateDirectory of a service with DynamicUser enabled.
    # Just going to add /var/lib/private as a persisted directory in core.
    #sebastianrasor.persistence.directories = [config.services.actual.settings.dataDir];

    #sebastianrasor.unas.mounts."Actual" = "/media/actual";

    services.nginx.virtualHosts."actual.ts.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.actual.settings.port}";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_ssl_server_name on;
          proxy_pass_header Authorization;
        '';
      };
    };
  };
}
