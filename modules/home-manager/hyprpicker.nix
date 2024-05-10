{ pkgs, lib, ... }: {
  wayland.windowManager.hyprland.settings.bind = [ "SUPER_SHIFT, C, exec, ${lib.getExe pkgs.hyprpicker} -a -n" ];
}
