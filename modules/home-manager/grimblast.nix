{ lib, pkgs, ... }: {
  wayland.windowManager.hyprland.settings.bind = [
    ", Print, exec, ${lib.getExe pkgs.grimblast} copy output"
    "SUPER, Print, exec, ${lib.getExe pkgs.grimblast} copysave output"
    "ALT, Print, exec, ${lib.getExe pkgs.grimblast} copy active"
    "SUPER_ALT, Print, exec, ${lib.getExe pkgs.grimblast} copysave active"
    "SUPER_SHIFT, S, exec, ${lib.getExe pkgs.grimblast} copy area"
  ];
}
