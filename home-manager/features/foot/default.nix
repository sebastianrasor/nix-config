{ pkgs, ... }: {
  home.packages = with pkgs; [
    foot

    (nerdfonts.override {
      fonts = [
        "IntelOneMono"
      ];
    })
  ];

  wayland.windowManager.hyprland.settings.bind = [ "SUPER, Return, exec, ${pkgs.foot}/bin/footclient" ];

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

  xdg.desktopEntries.foot = {
    name = "Foot";
    noDisplay = true;
  };

  xdg.desktopEntries.foot-server = {
    name = "Foot Server";
    noDisplay = true;
  };

  xdg.desktopEntries.footclient = {
    name = "Foot"; # call it foot instead of foot client
  };
}
