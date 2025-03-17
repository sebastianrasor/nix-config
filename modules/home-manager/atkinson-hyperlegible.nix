{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.atkinson-hyperlegible.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.atkinson-hyperlegible.enable {
    fonts.fontconfig.enable = true;
    home.packages = [pkgs.atkinson-hyperlegible];
  };
}
