{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.systemd-boot.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.systemd-boot.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
