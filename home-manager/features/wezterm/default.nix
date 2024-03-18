{ pkgs, ... }: {
  home.packages = with pkgs; [
    wezterm

    (nerdfonts.override {
      fonts = [
        "IntelOneMono"
      ];
    })
  ];

  wayland.windowManager.hyprland.settings.bind = [ "SUPER, Return, exec, ${pkgs.wezterm}/bin/wezterm" ];

  programs.wezterm = {
    enable = true; 
    extraConfig =
      ''
        return {
          font = wezterm.font("Atkinson Hyperlegible"),
          font_size = 12.0
        }
      '';
  };
}
