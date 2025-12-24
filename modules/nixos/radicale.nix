{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.radicale;
in
{
  options.sebastianrasor.radicale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
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

    sebastianrasor.reverse-proxy.proxies."radicale" = "http://127.0.0.1:5232";

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
  };
}
