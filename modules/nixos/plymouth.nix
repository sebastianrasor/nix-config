{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.plymouth;
in
{
  options.sebastianrasor.plymouth = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      consoleLogLevel = 0;
      initrd.verbose = false;
      loader.timeout = 0;
      plymouth.enable = true;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
    };
  };
}
