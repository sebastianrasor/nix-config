{ pkgs, lib, config, inputs, ... }: {
  services.hypridle = {
    enable = true;
    settings = {
      beforeSleepCmd = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
      lockCmd = "${lib.getExe' pkgs.procps "pidof"} hyprlock || ${lib.getExe config.programs.hyprlock.package}";
      unlockCmd = "${lib.getExe' pkgs.procps "pkill"} -USR1 hyprlock";
      listeners = [
        {
          timeout = 30;
          onTimeout = ''
            ${lib.getExe pkgs.brillo} -O && [ "$(echo "$(${lib.getExe pkgs.brillo} -G) > 30" | ${lib.getExe' pkgs.bc "bc"})" -eq "1" ] && ${lib.getExe pkgs.brillo} -S 30
          '';
          onResume = "${lib.getExe pkgs.brillo} -I";
        }
        {
          timeout = 300;
          onTimeout = ''
            ${lib.getExe pkgs.brillo} -u 10000000 -S 0 && ${lib.getExe' pkgs.systemd "loginctl"} lock-session && ${lib.getExe' pkgs.hyprland "hyprctl"} dispatch dpms off
          '';
          onResume = "${lib.getExe' pkgs.procps "pkill"} brillo; ${lib.getExe pkgs.brillo} -I";
        }
        {
          timeout = 1200;
          onTimeout = "${lib.getExe' pkgs.systemd "systemctl"} suspend-then-hibernate";
        }
      ];
    };
  };
}
