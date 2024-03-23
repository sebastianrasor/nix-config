{ pkgs, lib, config, inputs, ... }: {
  imports = [
    inputs.hypridle.homeManagerModules.hypridle
  ];

  home.packages = with pkgs; [
    bc
  ];


  services.hypridle = {
    enable = true;
    beforeSleepCmd = "${pkgs.systemd}/bin/loginctl lock-session";
    afterSleepCmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
    lockCmd = "${pkgs.procps}/bin/pidof hyprlock || ${lib.getExe config.programs.hyprlock.package}";
    unlockCmd = "${pkgs.procps}/bin/pkill -USR1 hyprlock";
    listeners = [
      {
        timeout = 30;
        onTimeout = ''
          ${pkgs.brillo}/bin/brillo -O && [ "$(echo "$(${pkgs.brillo}/bin/brillo -G) > 30" | ${pkgs.bc}/bin/bc)" -eq "1" ] && ${pkgs.brillo}/bin/brillo -S 30
        '';
        onResume = "${pkgs.brillo}/bin/brillo -I";
      }
      {
        timeout = 300;
        onTimeout = ''
          ${pkgs.brillo}/bin/brillo -u 10000000 -S 0 && ${pkgs.hyprland}/bin/hyprctl dispatch dpms off && ${pkgs.systemd}/bin/loginctl lock-session
        '';
        onResume = "${pkgs.brillo}/bin/brillo -I && ${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
      }
      {
        timeout = 1200;
        onTimeout = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };
}
