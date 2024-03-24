{ config, inputs, ... }: {
  imports = [
    inputs.hyprpaper.homeManagerModules.hyprpaper
  ];

  services.hyprpaper = {
    enable = true;
    wallpapers = [
      "eDP-1,${config.home.homeDirectory}/pictures/wallpapers/nix-wallpaper-nineish.png"
    ];
    preloads = [
      "${config.home.homeDirectory}/pictures/wallpapers/nix-wallpaper-nineish.png"
    ];
  };
}
