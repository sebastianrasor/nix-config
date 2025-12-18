{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.systemd-boot;
in
{
  options.sebastianrasor.systemd-boot = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
