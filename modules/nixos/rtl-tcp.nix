{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.rtl-tcp;
in
{
  options.sebastianrasor.rtl-tcp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.rtl-sdr.enable = true;
    systemd.services.rtl-tcp = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "rtl_tcp service (for rtlamr)";
      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.rtl-sdr "rtl_tcp"} -a 0.0.0.0";
        Restart = "on-failure";
        KillMode = "control-group";
      };
    };
  };
}
