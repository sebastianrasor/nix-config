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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.auto-rotate = {
      Unit.Description = "Automatically rotates the screen";
      Install.WantedBy = [ "default.target" ];
      Service.ExecStart =
        let
          autoRotateScript = pkgs.writeShellApplication {
            name = "minecraft-world-backup";
            runtimeInputs = with pkgs; [
              iio-sensor-proxy
              wlr-randr
            ];
            text = ''
              monitor-sensor --accel | while IFS= read -r line; do
              	case "$line" in
              	*"Accelerometer orientation changed: normal") wlr-randr --output eDP-1 --transform normal ;;
              	*"Accelerometer orientation changed: left-up") wlr-randr --output eDP-1 --transform 90 ;;
              	*"Accelerometer orientation changed: bottom-up") wlr-randr --output eDP-1 --transform 180 ;;
              	*"Accelerometer orientation changed: right-up") wlr-randr --output eDP-1 --transform 270 ;;
              	esac
              done
            '';
          };
        in
        lib.getExe autoRotateScript;
    };
  };
}
