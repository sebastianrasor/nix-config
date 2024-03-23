{ pkgs, ... }: {
  wayland.windowManager.hyprland.settings.bind = [
    ", xf86MonBrightnessUp, exec, ${pkgs.brillo}/bin/brillo -A 10"
    ", xf86MonBrightnessDown, exec, ${pkgs.brillo}/bin/brillo -U 10"
  ];
}
