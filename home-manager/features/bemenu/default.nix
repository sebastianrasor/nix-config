{ pkgs, ... }: {
  home.packages = with pkgs; [ bemenu ];

  wayland.windowManager.hyprland.settings.bind = [ "SUPER, R, exec, ${pkgs.bemenu}/bin/bemenu-run" ];

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
