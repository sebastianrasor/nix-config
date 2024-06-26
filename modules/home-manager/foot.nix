{ lib, pkgs, ... }: {
  wayland.windowManager.hyprland.settings.bind = [ "SUPER, Return, exec, ${lib.getExe' pkgs.foot "footclient"}" ];

  home.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "IntelOneMono"
      ];
    })
  ];

  programs.foot = {
    enable = true; 
    server.enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "IntoneMono Nerd Font:size=12";
        dpi-aware = "yes";
      };
      mouse = {
        hide-when-typing = "yes";
      };
    };
  };

  xdg.desktopEntries = {
    "org.codeberg.dnkl.foot" = {
      name = "Foot";
      noDisplay = true;
    };

    "org.codeberg.dnkl.foot-server" = {
      name = "Foot Server";
      noDisplay = true;
    };

    "org.codeberg.dnkl.footclient" = {
      name = "Foot"; # call it foot instead of foot client
    };
  };
}
