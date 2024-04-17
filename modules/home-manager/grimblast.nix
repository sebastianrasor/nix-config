{ lib, pkgs, inputs, ... }:
let
  grimblast = inputs.hypr-contrib.packages.${pkgs.system}.grimblast;
in
{
  wayland.windowManager.hyprland.settings.bind = [
    ", Print, exec, ${lib.getExe grimblast} copy output"
    "SUPER, Print, exec, ${lib.getExe grimblast} copysave output"
    "ALT, Print, exec, ${lib.getExe grimblast} copy active"
    "SUPER_ALT, Print, exec, ${lib.getExe grimblast} copysave active"
    "SUPER_SHIFT, S, exec, ${lib.getExe grimblast} copy area"
  ];
}
