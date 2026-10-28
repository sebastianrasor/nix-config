{ constants, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.tailscale-golink;
  dataDir = "/var/lib/golink";
in
{
  options.sebastianrasor.tailscale-golink = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.golink = { };
    users.users.golink = {
      home = dataDir;
      createHome = true;
      group = "golink";
      isSystemUser = true;
    };

    systemd.services.golink = {
      wantedBy = [ "multi-user.target" ];
      script = ''
        export TS_AUTHKEY="$(head -n1 "$CREDENTIALS_DIRECTORY/authKey")"
        exec ${lib.getExe pkgs.golink} \
          --sqlitedb ${dataDir}/golink.db \
          --control-url https://headscale.${constants.domain}
      '';
      serviceConfig = {
        User = "golink";
        Group = "golink";
        LoadCredential = [
          "authKey:${config.sops.secrets."tailscale/authKey".path}"
        ];
        Restart = "always";
        RestartSec = "15";
        WorkingDirectory = dataDir;
      };
    };

    sebastianrasor.persistence.directories = [ dataDir ];

    sops.secrets."tailscale/authKey" = { };
  };
}
