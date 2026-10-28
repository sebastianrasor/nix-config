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
    enable = lib.mkEnableOption "Atkinson Hyperlegible fonts";
  };

  config = lib.mkIf cfg.enable {
    packages = with pkgs; [
      atkinson-hyperlegible
      atkinson-hyperlegible-next
      atkinson-hyperlegible-mono
    ];

    xdg.data.files = {
      "fonts/atkinson-hyperlegible".source = "${pkgs.atkinson-hyperlegible}/share/fonts";
      "fonts/atkinson-hyperlegible-next".source = "${pkgs.atkinson-hyperlegible-next}/share/fonts";
      "fonts/atkinson-hyperlegible-mono".source = "${pkgs.atkinson-hyperlegible-mono}/share/fonts";
    };

    xdg.config.files."fontconfig/conf.d/51-atkinson-hyperlegible.conf".source = ./fonts.conf;
  };
}
