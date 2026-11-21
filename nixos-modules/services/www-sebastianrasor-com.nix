_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.www-sebastianrasor-com;
in
{
  options.sebastianrasor.www-sebastianrasor-com = {
    enable = lib.mkEnableOption "www.sebastianrasor.com";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.www-sebastianrasor-com = {
      description = "My personal website";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        CapabilityBoundingSet = "";
        DynamicUser = true;
        Environment = [
          "WWW_SMTP_CONNECTION_URL_FILE=%d/smtpConnectionUrl"
          "WWW_TO_MAILBOX_FILE=%d/toMailbox"
        ];
        ExecStart = "${lib.getExe pkgs.www-sebastianrasor-com}";
        LoadCredential = [
          "smtpConnectionUrl:${config.sops.secrets."mxroute/smtpConnectionUrl".path}"
          "toMailbox:${config.sops.secrets."www-sebastianrasor-com/toMailbox".path}"
        ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        Restart = "on-failure";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RuntimeDirectory = "www-sebastianrasor-com";
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        UMask = "0077";
      };
    };

    sebastianrasor.reverse-proxy.proxies."www.sebastianrasor.com" = {
      public = true;
      target = "http://127.0.0.1:2002";
      maxBodySize = "128k";
      timeout = "30s";
    };

    sops.secrets = {
      "mxroute/smtpConnectionUrl" = { };
      "www-sebastianrasor-com/toMailbox" = { };
    };
  };
}
