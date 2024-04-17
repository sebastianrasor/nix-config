{ pkgs, ... }: {
  home.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "IntelOneMono"
      ];
    })
  ];

  wayland.windowManager.hyprland.settings.bind = [ "SUPER, Return, exec, ${lib.getExe pkgs.wezterm}" ];

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
