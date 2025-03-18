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
    home.packages = with pkgs; [
      atkinson-hyperlegible
      atkinson-hyperlegible-next
      atkinson-hyperlegible-mono
    ];
  };
}
