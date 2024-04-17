{ pkgs, inputs, lib, ... }:
let
  hyprpicker = inputs.hyprpicker.packages."${pkgs.system}".hyprpicker;
in
{
  wayland.windowManager.hyprland.settings.bind = [ "SUPER_SHIFT, C, exec, ${lib.getExe hyprpicker} -a -n" ];
}
