{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.checkemail;
in
{
  options.sebastianrasor.checkemail = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.checkemail-env = lib.mkIf config.sebastianrasor.secrets.enable { };
    systemd.services.checkemail = {
      description = "checkemail";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.checkemail-env.path;
        ExecStart = "${lib.getExe' inputs.checkemail.packages.${pkgs.stdenv.hostPlatform.system}.default
          "checkemail"
        }";
        Restart = "always";
      };
    };

    sebastianrasor.reverse-proxy.proxies."checkemail" = "http://127.0.0.1:3000";
  };
}
