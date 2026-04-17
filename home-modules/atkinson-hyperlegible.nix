_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.atkinson-hyperlegible;
in
{
  options.sebastianrasor.atkinson-hyperlegible = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Atkinson Hyperlegible Mono" ];
        sansSerif = [ "Atkinson Hyperlegible Next" ];
      };
      antialiasing = true;
      hinting = "full";
      subpixelRendering = "rgb";
    };
    home.packages = with pkgs; [
      atkinson-hyperlegible
      atkinson-hyperlegible-next
      atkinson-hyperlegible-mono
    ];
  };
}
