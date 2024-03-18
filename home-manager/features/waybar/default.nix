{ pkgs, ... }: {
  home.packages = with pkgs; [ waybar ];
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;
        spacing = 8;
        margin-top = 0;
        margin-bottom = 0;
        padding-top = 0;
        padding-bottom = 0;
        modules-left = [ "custom/launcher" ];
        modules-center = [];
        modules-right = [ "battery" "custom/clock" ];
        "hyprland/workspaces" = {
          "format" = "{icon}";
          "on-scroll-up" = "hyprctl dispatch workspace e+1";
          "on-scroll-down" = "hyprctl dispatch workspace e-1";
        };
        "custom/clock" = {
          format = "{}";
          tooltip = false;
          restart-interval = 1;
          exec = "${pkgs.clock}/bin/clock";
        };
        "custom/launcher" = {
          format = "";
          on-click = "${pkgs.bemenu}/bin/bemenu-run";
        };
      };
    };
    style =
      ''
        * {
          border: none;
          border-radius: 0;
          font-family: Atkinson Hyperlegible;
        }
        window#waybar {
          background: #000;
          color: #fff;
        }
      '';
  };
}
