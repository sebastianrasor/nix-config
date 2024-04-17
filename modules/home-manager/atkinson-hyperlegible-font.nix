{ pkgs, ... }: {
  home.packages = with pkgs; [ atkinson-hyperlegible ];
  fonts.fontconfig.enable = true;
}
