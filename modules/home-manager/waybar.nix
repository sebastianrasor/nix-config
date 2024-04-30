{ lib, pkgs, ... }: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;
        spacing = 12;
        margin-top = 0;
        margin-bottom = 0;
        padding-top = 0;
        padding-bottom = 0;
        modules-left = [ "custom/launcher" "hyprland/workspaces" ];
        modules-center = [];
        modules-right = [ "wireplumber" "network" "battery" "custom/clock" ];
        "wireplumber" = {
            "format" = "{icon} ";
            "format-muted" = "󰝟 ";
            "format-icons" = [ "󰕿" "󰖀" "󰕾"];
            "on-click" = "${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
        "network" = {
          "tooltip" = true;
          "tooltip-format" = "{ipaddr}";
          "format-wifi" = "{icon}";
          "format-ethernet" = "󰈀 ";
          "format-disconnected" = "󰤮 ";
          "format-icons" = [
            "󰤯 "
            "󰤟 "
            "󰤢 "
            "󰤥 "
            "󰤨 "
          ];
        };
        "battery" = {
          "format" = "{icon}";
          "rotate" = "90";
          "tooltip-format" = "{capacity}%";
          "format-icons" = [
            "󰂎" # empty
            "󰁺" # 10%
            "󰁻" # 20%
            "󰁼" # 30%
            "󰁽" # 40%
            "󰁾" # 50%
            "󰁿" # 60%
            "󰂀" # 70%
            "󰂁" # 80%
            "󰂂" # 90%
            "󰁹" # full
          ];
        };
        "hyprland/workspaces" = {
          "persistent-workspaces" = {
            "*" = [ 1 2 3 4 5 6 7 8 9 10 ];
          };
          "format" = "{icon}";
          "format-icons" = {
            "1" = "󰎤";
            "2" = "󰎧";
            "3" = "󰎪";
            "4" = "󰎭";
            "5" = "󰎱";
            "6" = "󰎳";
            "7" = "󰎶";
            "8" = "󰎹";
            "9" = "󰎼";
            "10" = "󰽽";
          };
          "on-scroll-up" = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch workspace e+1";
          "on-scroll-down" = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch workspace e-1";
        };
        "custom/clock" = {
          format = "{}";
          tooltip = false;
          restart-interval = 1;
          exec = ''
            while :; do
              ${lib.getExe' pkgs.coreutils-full "date"} '+%-I:%M %p'
              ${lib.getExe pkgs.snooze} -H '*' -M '*' -S '0' &
              snooze_pid=$!
              echo $snooze_pid > /run/user/$UID/waybar-clock-snooze-pid
              wait $snooze_pid
            done
          '';
        };
        "custom/launcher" = {
          format = "";
          tooltip = false;
        };
      };
    };
    style =
      ''
        * {
          border: none;
          border-radius: 0;
          font-family: Atkinson Hyperlegible;
          font-size: 12pt;
        }
        window#waybar {
          background: #000;
          color: #fff;
        }

        #workspaces button {
          background-color: #000000;
          color: #7F7F7F;
          padding: 0;
          margin: 0;
          transition-property: color;
          transition-duration: .2s;
        }
        #workspaces button:hover {
          box-shadow: none; /* Remove predefined box-shadow */
          text-shadow: none; /* Remove predefined text-shadow */
          background: none; /* Remove predefined background color (white) */
          transition: none; /* Disable predefined animations */
        }
        #workspaces button.empty {
          background-color: #000000;
          color: #3F3F3F;
        }
        #workspaces button.visible {
          background-color: #000000;
          color: #BFBFBF;
        }
        #workspaces button.active {
          background-color: #000000;
          color: #FFFFFF;
        }
        #workspaces {
          padding-left: 6;
          padding-right: 6;
          margin: inherit;
        }
        #custom-clock {
          padding-right: 12;
        }
        #custom-launcher {
          padding-left: 12;
        }
      '';
  };
}
