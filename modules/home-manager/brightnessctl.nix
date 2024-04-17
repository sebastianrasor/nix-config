{ lib, pkgs, ... }: {
  wayland.windowManager.hyprland.settings.bind = [
    ", xf86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} --min-value=1 set +10%"
    ", xf86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} --min-value=1 set 10%-"
  ];
}
