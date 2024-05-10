{ pkgs, lib, config, inputs, ... }: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        before_sleep_cmd = ''${lib.getExe' pkgs.systemd "loginctl"} lock-session'';
        ignore_dbus_inhibit = false;
      };
      listener = [
        {
          timeout = 30;
          on-timeout = ''
            ${lib.getExe pkgs.brillo} -O && [ "$(echo "$(${lib.getExe pkgs.brillo} -G) > 30" | ${lib.getExe' pkgs.bc "bc"})" -eq "1" ] && ${lib.getExe pkgs.brillo} -S 30
          '';
          on-resume = "${lib.getExe pkgs.brillo} -I";
        }
        {
          timeout = 300;
          on-timeout = ''${lib.getExe' pkgs.systemd "loginctl"} lock-session'';
        }
        {
          timeout = 600;
          on-timeout = ''
            ${lib.getExe pkgs.brillo} -u 10000000 -S 0 && ${lib.getExe' pkgs.hyprland "hyprctl"} dispatch dpms off
          '';
          on-resume = "${lib.getExe' pkgs.procps "pkill"} brillo; ${lib.getExe pkgs.brillo} -I";
        }
        {
          timeout = 1200;
          on-timeout = "${lib.getExe' pkgs.systemd "systemctl"} suspend-then-hibernate";
        }
      ];
    };
  };
}
