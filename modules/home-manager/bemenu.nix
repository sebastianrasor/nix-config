{ lib, pkgs, ... }: {
  wayland.windowManager.hyprland.settings.bind = [ "SUPER, D, exec, ${lib.getExe pkgs.j4-dmenu-desktop} --no-generic --dmenu='${lib.getExe pkgs.bemenu} -p Launcher:'" ];

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
