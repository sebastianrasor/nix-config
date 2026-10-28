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
    packages = with pkgs; [
      noto-fonts-color-emoji
    ];

    xdg.data.files."fonts/noto-fonts-color-emoji".source = "${pkgs.noto-fonts-color-emoji}/share/fonts";

    xdg.config.files."fontconfig/conf.d/52-emoji.conf".source = ./fonts.conf;
  };
}
