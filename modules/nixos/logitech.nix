{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.logitech.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.logitech.enable {
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}
