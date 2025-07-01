{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.immich.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.immich.enable {
    users.users.immich.extraGroups = [
      "video"
      "render"
    ];

    services.immich = {
      accelerationDevices = null;
      enable = true;
      mediaLocation = lib.mkIf config.sebastianrasor.unas.enable "/media/immich";
    };

    systemd.services.immich.unitConfig.RequiresMountsFor = lib.mkIf config.sebastianrasor.unas.enable ["/media/immich"];
    systemd.services.immich.bindsTo = lib.mkIf config.sebastianrasor.unas.enable ["media-immich.mount"];
    fileSystems."/media/immich" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Immich";
      fsType = "nfs";
    };

    services.nginx.virtualHosts."immich.rasor.us" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://[::1]:${toString config.services.immich.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
      };
    };
  };
}
