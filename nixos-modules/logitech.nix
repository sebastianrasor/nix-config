{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.logitech;
in
{
  options.sebastianrasor.logitech = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}
