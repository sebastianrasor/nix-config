{ pkgs, ... }: {
  home.packages = with pkgs; [
    brightnessctl
  ];
  wayland.windowManager.hyprland.settings.bind = [
    ", xf86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl --min-value=1 set +10%"
    ", xf86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl --min-value=1 set 10%-"
  ];
}
