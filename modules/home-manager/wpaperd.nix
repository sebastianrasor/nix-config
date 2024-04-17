{ config, ... }: {
  programs.wpaperd = {
    enable = true;
    settings = {
      default = {
        path = "${config.home.homeDirectory}/pictures/wallpapers";
        sorting = "random";
      };
    };
  };
}
