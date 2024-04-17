{ config, inputs, ... }: {
  imports = [
    inputs.hyprpaper.homeManagerModules.hyprpaper
  ];

  services.hyprpaper = {
    enable = true;
    wallpapers = [
      "eDP-1,${config.xdg.userDirs.pictures}/wallpapers/nix-wallpaper-nineish.png"
    ];
    preloads = [
      "${config.xdg.userDirs.pictures}/wallpapers/nix-wallpaper-nineish.png"
    ];
  };
}
