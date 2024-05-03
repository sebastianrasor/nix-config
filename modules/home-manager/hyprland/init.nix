{ lib, pkgs, ... }: {
  programs.bash.initExtra =
    ''
      if [ "$(tty)" = "/dev/tty1" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        exec ${lib.getExe pkgs.hyprland};
      fi
    '';
}
