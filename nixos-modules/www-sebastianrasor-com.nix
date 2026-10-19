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
          "SMTP_PASSWORD_FILE=%d/smtpPassword"
          "SMTP_RELAY_FILE=%d/smtpRelay"
          "SMTP_USERNAME_FILE=%d/smtpUsername"
          "TO_DOMAIN_FILE=%d/toDomain"
          "TO_USER_FILE=%d/toUser"
          "TURNSTILE_SECRET_KEY_FILE=%d/turnstileSecretKey"
        ];
        ExecStart = "${lib.getExe www-sebastianrasor-com}";
        LoadCredential = [
          "smtpPassword:${config.sops.secrets."mxroute/password".path}"
          "smtpRelay:${config.sops.secrets."mxroute/relay".path}"
          "smtpUsername:${config.sops.secrets."mxroute/username".path}"
          "toDomain:${config.sops.secrets."www-sebastianrasor-com/toDomain".path}"
          "toUser:${config.sops.secrets."www-sebastianrasor-com/toUser".path}"
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
      "mxroute/password" = { };
      "mxroute/relay" = { };
      "mxroute/username" = { };
      "www-sebastianrasor-com/toDomain" = { };
      "www-sebastianrasor-com/toUser" = { };
      "cloudflare/turnstileSecretKey" = { };
    };
  };
}
