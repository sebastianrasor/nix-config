{ pkgs, config, ... }: {
  home.packages = with pkgs; [ wpaperd ];
  programs.wpaperd = {
    enable = true;
    settings = {
      default = {
        path = "${config.home.homeDirectory}/Pictures/Wallpapers";
        sorting = "random";
      };
    };
  };
}
