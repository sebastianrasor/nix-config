{ lib, pkgs, inputs, config, ... }: {
  imports = [
    inputs.hyprlock.homeManagerModules.hyprlock
  ];

  programs.hyprlock = {
    enable = true;
    general = {
      disable_loading_bar = true;
      hide_cursor = false;
      no_fade_in = false;
    };
    backgrounds = [
      {
        monitor = "";
        path = "screenshot";
        blur_passes = 3;
        #blur_size = 8;
      }
    ];
    input-fields = [
      {
        #monitor = "";

        size = {
          width = 250;
          height = 60;
        };

        outline_thickness = 2;

        dots_size = 0.2;
        dots_spacing = 0.2;
        dots_center = true;

        outer_color = "rgba(0,0,0,0)";
        inner_color = "rgba(0,0,0,0.5)";
        font_color = "rgb(255,255,255)";

        fade_on_empty = false;
        placeholder_text = ''<span foreground='##FFFFFF7F' font_family='Atkinson Hyperlegible'>Password...</span>'';
      }
    ];
    labels = [
      {
        monitor = "";
        text =
        ''
          cmd[update:1000] echo "<span>''$(${lib.getExe' pkgs.coreutils-full "date"} '+%-I:%M %p')</span>"
        '';
        font_family = "Atkinson Hyperlegible";
        font_size = 120;
        color = "rgba(255,255,255,0.6)";

        position = {
          x = 0;
          y = -240;
        };

        valign = "top";
        halign = "center";
      }
    ];

  };
}
