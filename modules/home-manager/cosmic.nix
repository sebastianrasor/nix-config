{
  config,
  cosmicLib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.cosmic;
in
{
  options.sebastianrasor.cosmic = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    wayland.desktopManager.cosmic = {
      enable = true;
      appearance = {
        theme.dark.accent = cosmicLib.cosmic.mkRON "optional" {
          red = cosmicLib.cosmic.mkRON "raw" "0.57254905";
          green = cosmicLib.cosmic.mkRON "raw" "0.8117647";
          blue = cosmicLib.cosmic.mkRON "raw" "0.6117647";
        };
        toolkit = {
          interface_font = {
            family = "Atkinson Hyperlegible Next";
            stretch = cosmicLib.cosmic.mkRON "enum" "Normal";
            style = cosmicLib.cosmic.mkRON "enum" "Normal";
            weight = cosmicLib.cosmic.mkRON "enum" "Normal";
          };
          monospace_font = {
            family = "Atkinson Hyperlegible Mono";
            stretch = cosmicLib.cosmic.mkRON "enum" "Normal";
            style = cosmicLib.cosmic.mkRON "enum" "Normal";
            weight = cosmicLib.cosmic.mkRON "enum" "Normal";
          };
        };
      };
      compositor = {
        autotile = true;
        workspaces = {
          workspace_layout = cosmicLib.cosmic.mkRON "enum" "Horizontal";
          workspace_mode = cosmicLib.cosmic.mkRON "enum" "OutputBound";
        };
        input_default = {
          state = cosmicLib.cosmic.mkRON "enum" "Enabled";
          acceleration = cosmicLib.cosmic.mkRON "optional" {
            profile = cosmicLib.cosmic.mkRON "optional" (cosmicLib.cosmic.mkRON "enum" "Flat");
            speed = 0.0;
          };
        };
        input_touchpad = {
          state = cosmicLib.cosmic.mkRON "enum" "Enabled";
          click_method = cosmicLib.cosmic.mkRON "optional" (cosmicLib.cosmic.mkRON "enum" "Clickfinger");
          acceleration = cosmicLib.cosmic.mkRON "optional" {
            profile = cosmicLib.cosmic.mkRON "optional" (cosmicLib.cosmic.mkRON "enum" "Adaptive");
            speed = 0.0;
          };
          scroll_config = cosmicLib.cosmic.mkRON "optional" {
            method = cosmicLib.cosmic.mkRON "optional" (cosmicLib.cosmic.mkRON "enum" "TwoFinger");
            natural_scroll = cosmicLib.cosmic.mkRON "optional" false;
            scroll_button = cosmicLib.cosmic.mkRON "optional" null;
            scroll_factor = cosmicLib.cosmic.mkRON "optional" null;
          };
          tap_config = cosmicLib.cosmic.mkRON "optional" {
            enabled = true;
            button_map = cosmicLib.cosmic.mkRON "optional" (cosmicLib.cosmic.mkRON "enum" "LeftRightMiddle");
            drag = true;
            drag_lock = false;
          };
        };
        xkb_config = {
          layout = "us";
          model = "pc104";
          options = cosmicLib.cosmic.mkRON "optional" "terminate:ctrl_alt_bksp";
          repeat_delay = 600;
          repeat_rate = 25;
          rules = "";
          variant = "dvorak";
        };
      };
      idle = {
        screen_off_time = cosmicLib.cosmic.mkRON "optional" 900000;
        suspend_on_ac_time = cosmicLib.cosmic.mkRON "optional" 3600000;
        suspend_on_battery_time = cosmicLib.cosmic.mkRON "optional" 1800000;
      };
      panels = [
        {
          name = "Panel";
          autohide = cosmicLib.cosmic.mkRON "optional" null;
          anchor = cosmicLib.cosmic.mkRON "enum" "Top";
          border_radius = 0;
          output = cosmicLib.cosmic.mkRON "raw" "All";
          anchor_gap = false;
          margin = 0;
          expand_to_edges = true;
          #background = cosmicLib.cosmic.mkRON "raw" "ThemeDefault";
          size = cosmicLib.cosmic.mkRON "raw" "XS";
          opacity = 1.0;
          plugins_center = cosmicLib.cosmic.mkRON "optional" [
            "com.system76.CosmicAppletTime"
          ];
          plugins_wings = cosmicLib.cosmic.mkRON "optional" (
            cosmicLib.cosmic.mkRON "tuple" [
              [
                "com.system76.CosmicAppletWorkspaces"
              ]
              [
                "com.system76.CosmicAppletStatusArea"
                "com.system76.CosmicAppletTiling"
                "com.system76.CosmicAppletAudio"
                "com.system76.CosmicAppletNetwork"
                "com.system76.CosmicAppletBattery"
                "com.system76.CosmicAppletNotifications"
                "com.system76.CosmicAppletBluetooth"
                "com.system76.CosmicAppletPower"
              ]
            ]
          );
        }
      ];
      shortcuts = [
        {
          action = cosmicLib.cosmic.mkRON "enum" "Disable";
          key = "Super";
        }
      ];
      systemActions = cosmicLib.cosmic.mkRON "map" [
        {
          key = cosmicLib.cosmic.mkRON "enum" "Terminal";
          value = "cosmic-term";
        }
      ];
      wallpapers = [
        {
          filter_by_theme = false;
          rotation_frequency = 300;
          filter_method = cosmicLib.cosmic.mkRON "enum" "Lanczos";
          scaling_mode = cosmicLib.cosmic.mkRON "enum" "Zoom";
          sampling_method = cosmicLib.cosmic.mkRON "enum" "Alphanumeric";
          output = "all";
          source = cosmicLib.cosmic.mkRON "enum" {
            value = [
              (pkgs.fetchurl {
                url = "https://archive.org/download/bliss-600dpi/bliss-600dpi.png";
                sha256 = "1nj75n9dbacdladdmig849ppzg9li3yfg53shfwa21n483p48bd7";
              }).outPath
            ];
            variant = "Path";
          };
        }
      ];
    };

    programs.cosmic-term = {
      enable = true;
      profiles = [
        {
          is_default = true;
          hold = false;
          name = "Default";
          syntax_theme_dark = "COSMIC Dark";
          syntax_theme_light = "COSMIC Light";
        }
      ];
      settings = {
        font_name = "Atkinson Hyperlegible Mono";
        font_size = 16;
      };
    };

    home.file.".config/cosmic-initial-setup-done".text = "";
  };
}
