{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.radicale.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.radicale.enable {
    sops.secrets.radicale_users = lib.mkIf config.sebastianrasor.secrets.enable {
      owner = config.users.users.radicale.name;
      group = config.users.users.radicale.group;
    };

    users.users.radicale.extraGroups = lib.mkIf config.sebastianrasor.unas.enable ["unifi-drive-nfs"];
    systemd.services.radicale.unitConfig.RequiresMountsFor = lib.mkIf config.sebastianrasor.unas.enable ["/media/radicale"];
    systemd.services.radicale.bindsTo = lib.mkIf config.sebastianrasor.unas.enable ["media-radicale.mount"];
    fileSystems."/media/radicale" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Radicale";
      fsType = "nfs";
      options = ["nolock"];
    };

    services.radicale = {
      enable = true;
      settings = {
        server.hosts = ["127.0.0.1:5232"];
        auth = {
          type = "htpasswd";
          htpasswd_filename = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.radicale_users.path;
          htpasswd_encryption = "bcrypt";
        };
        storage = {
          filesystem_folder = "/media/radicale";
        };
      };
    };

    services.nginx.virtualHosts."radicale.rasor.us" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:5232";
        proxyWebsockets = true;
        extraConfig = "proxy_ssl_server_name on;" + "proxy_pass_header Authorization;";
      };
    };
  };
}
