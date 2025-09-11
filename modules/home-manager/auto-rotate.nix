{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.auto-rotate.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.auto-rotate.enable {
    systemd.user.services = {
      auto-rotate = {
        Unit = {
          Description = "Automaticaly rotates the screen";
        };
        Service = {
          ExecStart = pkgs.writeShellScript "auto-rotate" ''
            ${lib.getExe' pkgs.iio-sensor-proxy "monitor-sensor"} --accel | while IFS= read -r line; do
              case "$line" in
              *"Accelerometer orientation changed: normal") ${lib.getExe pkgs.wlr-randr} --output eDP-1 --transform normal ;;
              *"Accelerometer orientation changed: left-up") ${lib.getExe pkgs.wlr-randr} --output eDP-1 --transform 90 ;;
              *"Accelerometer orientation changed: bottom-up") ${lib.getExe pkgs.wlr-randr} --output eDP-1 --transform 180 ;;
              *"Accelerometer orientation changed: right-up") ${lib.getExe pkgs.wlr-randr} --output eDP-1 --transform 270 ;;
              esac
            done
          '';
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    };
  };
}
