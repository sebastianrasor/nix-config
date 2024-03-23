{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    inputs.hyprpicker.packages."${pkgs.system}".hyprpicker
  ];

  wayland.windowManager.hyprland.settings.bind = [ "SUPER_SHIFT, C, exec, ${inputs.hyprpicker.packages."${pkgs.system}".hyprpicker}/bin/hyprpicker -a -n" ];
}
