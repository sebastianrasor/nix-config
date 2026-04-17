{ self, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.checkemail;
  checkemail = self.packages.${pkgs.stdenv.hostPlatform.system}.checkemail;
in
{
  options.sebastianrasor.checkemail = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.checkemail = {
      description = "checkemail";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = config.sops.templates."checkemail.env".path;
        ExecStart = "${lib.getExe' checkemail "checkemail" }";
        Restart = "always";
      };
    };

    sops = {
      secrets."checkemail/token" = { };
      templates."checkemail.env".content = ''
        CHECKEMAIL_TOKEN=${config.sops.placeholder."checkemail/token"}
      '';
    };

    sebastianrasor.reverse-proxy.proxies."checkemail" = "http://127.0.0.1:3000";
  };
}
