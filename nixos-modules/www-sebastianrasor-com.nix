{ self, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.www-sebastianrasor-com;
  www-sebastianrasor-com = self.packages.${pkgs.stdenv.hostPlatform.system}.www-sebastianrasor-com;
  acmeEnabled = config.sebastianrasor.acme.enable;
  acmeBaseDomain = config.sebastianrasor.acme.baseDomainName;
in
{
  options.sebastianrasor.www-sebastianrasor-com = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
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
          "WWW_TURNSTILE_SECRET_KEY_FILE=%d/turnstileSecretKey"
        ];
        ExecStart = "${lib.getExe www-sebastianrasor-com}";
        LoadCredential = [
          "smtpConnectionUrl:${config.sops.secrets."mxroute/smtpConnectionUrl".path}"
          "toMailbox:${config.sops.secrets."www-sebastianrasor-com/toMailbox".path}"
          "turnstileSecretKey:${config.sops.secrets."cloudflare/turnstileSecretKey".path}"
        ];
        Restart = "on-failure";
        RuntimeDirectory = "www-sebastianrasor-com";
      };
    };

    services.nginx.virtualHosts."www.sebastianrasor.com" = {
      forceSSL = lib.mkForce acmeEnabled;
      useACMEHost = lib.mkIf acmeEnabled acmeBaseDomain;
      locations."/" = {
        proxyPass = lib.mkForce "http://127.0.0.1:2002";
      };
    };

    sebastianrasor.acme.extraDomainNames = [
      "www.sebastianrasor.com"
    ];

    sops.secrets = {
      "mxroute/smtpConnectionUrl" = { };
      "www-sebastianrasor-com/toMailbox" = { };
      "cloudflare/turnstileSecretKey" = { };
    };
  };
}
