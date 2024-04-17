{ lib, pkgs, ... }: {
  wayland.windowManager.hyprland.settings.bind = [
    ", xf86MonBrightnessUp, exec, ${lib.getExe pkgs.brillo} -A 10"
    ", xf86MonBrightnessDown, exec, ${lib.getExe pkgs.brillo} -U 10"
  ];
}
