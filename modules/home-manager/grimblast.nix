{ lib, pkgs, ... }: {
  wayland.windowManager.hyprland.settings.bind = [
    ", Print, exec, ${lib.getExe pkgs.grimblast} -f copy output"
    "SUPER, Print, exec, ${lib.getExe pkgs.grimblast} -f copysave output"
    "ALT, Print, exec, ${lib.getExe pkgs.grimblast} -f copy active"
    "SUPER_ALT, Print, exec, ${lib.getExe pkgs.grimblast} -f copysave active"
    "SUPER_SHIFT, S, exec, ${lib.getExe pkgs.grimblast} -f copy area"
  ];
}
