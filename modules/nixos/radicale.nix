{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.radicale.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.radicale.enable {
    services.radicale = {
      enable = true;
      settings = {
        server.hosts = [ "127.0.0.1:5232" ];
        auth = {
          type = "htpasswd";
          htpasswd_filename = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.radicale_users.path;
          htpasswd_encryption = "bcrypt";
        };
      };
    };

    sebastianrasor.unas.mounts."Radicale" = "/media/radicale";

    sebastianrasor.persistence.directories = [
      (
        if lib.hasAttrByPath [ "storage" "filesystem_folder" ] config.services.radicale.settings then
          config.services.radicale.settings.storage.filesystem_folder
        else
          "/var/lib/radicale/collections"
      )
    ];

    sops.secrets.radicale_users = lib.mkIf config.sebastianrasor.secrets.enable {
      owner = config.users.users.radicale.name;
      group = config.users.users.radicale.group;
    };

    services.nginx.virtualHosts."radicale.ts.${config.sebastianrasor.domain}" = {
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
