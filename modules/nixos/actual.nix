{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.actual.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.actual.enable {
    services.actual = {
      enable = true;
      settings = {
        loginMethod = "openid";
        allowedLoginMethods = ["openid"];
      };
    };

    systemd.services.actual = lib.mkIf config.sebastianrasor.unas.enable {
      bindsTo = ["var-lib-actual.mount"];
      unitConfig.RequiresMountsFor = ["/var/lib/actual"];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkForce "unifi-drive-nfs";
        Group = lib.mkForce "unifi-drive";
      };
    };

    fileSystems."/var/lib/actual" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Actual";
      fsType = "nfs";
    };

    services.nginx.virtualHosts."actual.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.actual.settings.port}";
        proxyWebsockets = true;
        extraConfig = "proxy_ssl_server_name on;" + "proxy_pass_header Authorization;";
      };
    };
  };
}
