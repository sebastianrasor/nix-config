{ lib, pkgs, inputs, config, ... }: {
  services.hypridle = {
    settings = {
      general = {
        lock_cmd = "${lib.getExe' pkgs.procps "pidof"} hyprlock || ${lib.getExe pkgs.hyprlock}";
        unlock_cmd = "${lib.getExe' pkgs.procps "pkill"} -USR1 hyprlock";
      };
    };
  };
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = false;
      };
      background = [
        {
          monitor = "";
          path = "${pkgs.nixos-artwork.wallpapers.nineish.src}";
          blur_passes = 3;
          #blur_size = 8;
        }
      ];
      input-field = [
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
      label = [
        {
          #monitor = "";
          text =
          ''
            cmd[update:1000] echo "<span>''$(${lib.getExe' pkgs.coreutils-full "date"} '+%-I:%M %p')</span>"
          '';
          font_family = "Atkinson Hyperlegible";
          font_size = 120;
          color = "rgba(255,255,255,0.6)";

          position = "0, -240";

          valign = "top";
          halign = "center";
        }
      ];
    };
  };
}
