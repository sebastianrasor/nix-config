{ pkgs, inputs, config, ... }: {
  imports = [
    inputs.hyprlock.homeManagerModules.hyprlock
  ];

  programs.hyprlock = {
    enable = true;
    general = {
      disable_loading_bar = true;
      hide_cursor = false;
      no_fade_in = true;
    };
    backgrounds = [
      {
        monitor = "";
        path = "${config.home.homeDirectory}/pictures/wallpapers/nix-wallpaper-nineish.png";
      }
    ];
    input-fields = [
      {
        #monitor = "";

        size = {
          width = 300;
          height = 50;
        };

        outline_thickness = 2;

        outer_color = "rgb(0,0,0)";
        inner_color = "rgb(255,255,255)";
        font_color = "rgb(0,0,0)";

        fade_on_empty = false;
        placeholder_text = ''<span font_family='Atkinson Hyperlegible'>Password...</span>'';

        dots_spacing = 0.3;
        dots_center = true;
      }
    ];
    labels = [
      {
        monitor = "";
        text =
        ''
          cmd[update:1000] echo "<span font_family='Atkinson Hyperlegible'>''$(${pkgs.coreutils-full}/bin/date '+%-I:%M %p')</span>"
        '';
        #inherit font_family;
        font_size = 50;
        color = "rgb(0,0,0)";

        position = {
          x = 0;
          y = 80;
        };

        valign = "center";
        halign = "center";
      }
    ];

  };
}
