{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.jellyfin.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.jellyfin.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
      logDir = lib.mkIf config.sebastianrasor.unas.enable "/media/jellyfin/log";
      dataDir = lib.mkIf config.sebastianrasor.unas.enable "/media/jellyfin";
      configDir = lib.mkIf config.sebastianrasor.unas.enable "/media/jellyfin/config";
    };

    users.users.jellyfin.extraGroups = lib.mkIf config.sebastianrasor.unas.enable ["unifi-drive-nfs"];

    security.acme.certs."jellyfin.sebastianrasor.com" = lib.mkIf config.sebastianrasor.acme.enable {
      dnsProvider = "cloudflare";
      environmentFile = "/nix/persist/acme-env";
    };

    fileSystems."/media/jellyfin" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Jellyfin";
      fsType = "nfs";
      options = ["nolock"];
    };

    fileSystems."/media/movies" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Movies";
      fsType = "nfs";
      options = [
        "nolock"
        "ro"
      ];
    };

    fileSystems."/media/shows" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Shows";
      fsType = "nfs";
      options = [
        "nolock"
        "ro"
      ];
    };

    services.nginx.virtualHosts."jellyfin.sebastianrasor.com" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
        extraConfig = "proxy_ssl_server_name on;" + "proxy_pass_header Authorization;";
      };
    };
  };
}
