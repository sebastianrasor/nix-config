{ pkgs, ... }: {
  services.playerctld = {
    enable = true;
  };
  wayland.windowManager.hyprland.settings.bind = [
    ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
    ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
    ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
  ];
}
