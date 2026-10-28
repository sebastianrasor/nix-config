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
        Restart = "on-failure";
        RuntimeDirectory = "www-sebastianrasor-com";
      };
    };

    sebastianrasor.reverse-proxy.proxies."www.sebastianrasor.com" = "http://127.0.0.1:2002";

    sops.secrets = {
      "mxroute/smtpConnectionUrl" = { };
      "www-sebastianrasor-com/toMailbox" = { };
    };
  };
}
