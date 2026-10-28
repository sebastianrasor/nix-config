_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.auto-rotate;
in
{
  options.sebastianrasor.auto-rotate = {
    enable = lib.mkEnableOption "screen auto-rotation";

    output = lib.mkOption {
      type = lib.types.str;
      default = "eDP-1";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.auto-rotate = {
      description = "Automatically rotates the screen";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart =
        let
          autoRotateScript = pkgs.writeShellApplication {
            name = "auto-rotate";
            runtimeInputs = with pkgs; [
              iio-sensor-proxy
              wlr-randr
            ];
            text = builtins.readFile ./auto-rotate.sh;
          };
        in
        "${lib.getExe autoRotateScript} ${lib.escapeShellArg cfg.output}";
    };
  };
}
