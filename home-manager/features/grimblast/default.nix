{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    inputs.hypr-contrib.packages.${pkgs.system}.grimblast
  ];

  wayland.windowManager.hyprland.settings.bind = [
    ", Print, exec, ${inputs.hypr-contrib.packages.${pkgs.system}.grimblast}/bin/grimblast copy output"
    "SUPER, Print, exec, ${inputs.hypr-contrib.packages.${pkgs.system}.grimblast}/bin/grimblast copysave output"
    "ALT, Print, exec, ${inputs.hypr-contrib.packages.${pkgs.system}.grimblast}/bin/grimblast copy active"
    "SUPER_ALT, Print, exec, ${inputs.hypr-contrib.packages.${pkgs.system}.grimblast}/bin/grimblast copysave active"
    "SUPER_SHIFT, S, exec, ${inputs.hypr-contrib.packages.${pkgs.system}.grimblast}/bin/grimblast copy area"
  ];
}
