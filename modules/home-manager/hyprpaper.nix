{ config, pkgs, ... }: {
  services.hyprpaper = {
    enable = true;
    settings = {
      wallpaper = [
        ",${pkgs.nixos-artwork.wallpapers.nineish.src}"
      ];
      preload = [
        "${pkgs.nixos-artwork.wallpapers.nineish.src}"
      ];
    };
  };
}
