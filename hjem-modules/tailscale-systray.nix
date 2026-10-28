_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.tailscale-systray;
in
{
  options.sebastianrasor.tailscale-systray = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.tailscale-systray = {
      description = "Official Tailscale systray application for Linux";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${lib.getExe pkgs.tailscale} systray";
    };
  };
}
