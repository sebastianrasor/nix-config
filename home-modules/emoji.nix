_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.emoji;
in
{
  options.sebastianrasor.emoji = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig = {
      enable = true;
      defaultFonts.emoji = [ "Noto Color Emoji" ];
      defaultFonts.monospace = lib.mkAfter [ "Noto Color Emoji" ];
      defaultFonts.sansSerif = lib.mkAfter [ "Noto Color Emoji" ];
      defaultFonts.serif = lib.mkAfter [ "Noto Color Emoji" ];
    };
    home.packages = with pkgs; [
      noto-fonts-color-emoji
    ];
  };
}
