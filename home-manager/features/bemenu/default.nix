{ pkgs, ... }: {
  home.packages = with pkgs; [
    bemenu
    j4-dmenu-desktop
  ];

  wayland.windowManager.hyprland.settings.bind = [ "SUPER, R, exec, ${pkgs.j4-dmenu-desktop}/bin/j4-dmenu-desktop --no-generic --dmenu=bemenu" ];

  programs.bemenu = {
    enable = true;
    settings = {
      line-height = 24;
      ignorecase = true;
      fn = "Atkinson Hyperlegible 12";
      fb = "#000000";
      ff = "#ffffff";
      nb = "#000000";
      nf = "#ffffff";
      tb = "#000000";
      hb = "#ffffff";
      tf = "#ffffff";
      hf = "#000000";
      af = "#ffffff";
      ab = "#000000";
    };
  };
}
