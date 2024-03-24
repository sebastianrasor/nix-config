{ lib, pkgs, ... }: {
  home.packages = with pkgs; [
    playerctl
  ];
  services.playerctld.enable = true;
  wayland.windowManager.hyprland.settings.bind = [
    ", XF86AudioPlay, exec, ${lib.getExe pkgs.playerctl} play-pause"
    ", XF86AudioNext, exec, ${lib.getExe pkgs.playerctl} next"
    ", XF86AudioPrev, exec, ${lib.getExe pkgs.playerctl} previous"
  ];
}
