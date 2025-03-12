{ config, lib, ... }:
{
  options = {
    sebastianrasor.homebox.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.homebox.enable {
    services.homebox.enable = true;

    users.users.homebox.extraGroups = lib.mkIf config.sebastianrasor.unas.enable [ "unifi-drive-nfs" ];

    fileSystems."/var/lib/homebox/data" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Homebox";
      fsType = "nfs";
    };

    security.acme.certs."homebox.sebastianrasor.com" = lib.mkIf config.sebastianrasor.acme.enable {
      dnsProvider = "cloudflare";
      environmentFile = "/nix/persist/acme-env";
    };

    services.nginx.virtualHosts."homebox.sebastianrasor.com" = {
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
