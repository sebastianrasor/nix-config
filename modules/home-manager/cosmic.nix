{
  config,
  cosmicLib,
  lib,
  ...
}: {
  options = {
    sebastianrasor.cosmic.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.cosmic.enable {
    wayland.desktopManager.cosmic = {
      enable = true;
      appearance = {
        theme.dark.accent = cosmicLib.cosmic.mkRON "optional" {
          red = 0.57254905;
          green = 0.8117647;
          blue = 0.6117647;
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
      panels = [
        {
          name = "Panel";
          autohide = cosmicLib.cosmic.mkRON "optional" null;
          anchor = cosmicLib.cosmic.mkRON "enum" "Top";
          output = cosmicLib.cosmic.mkRON "raw" "All";
          anchor_gap = false;
          expand_to_edges = true;
          #background = cosmicLib.cosmic.mkRON "raw" "ThemeDefault";
          size = cosmicLib.cosmic.mkRON "raw" "XS";
          opacity = 1.0;
          plugins_center = cosmicLib.cosmic.mkRON "optional" [
            "com.system76.CosmicAppletTime"
          ];
          plugins_wings = cosmicLib.cosmic.mkRON "optional" (cosmicLib.cosmic.mkRON "tuple" [
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
          ]);
        }
      ];
      shortcuts = [
        {
          action = cosmicLib.cosmic.mkRON "enum" "Disable";
          key = "Super";
        }
      ];
    };
    programs.cosmic-term.settings = {
      font_name = "Atkinson Hyperlegible Mono";
      font_size = 16;
    };
  };
}
