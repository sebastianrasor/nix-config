{ inputs, lib, pkgs, ... }: {
  programs.fish = {
    enable = true;
    loginShellInit =
      ''
        if [ "$(tty)" = "/dev/tty1" ]; and [ -z "$WAYLAND_DISPLAY" ];
          exec ${lib.getExe pkgs.hyprland};
        end
      '';
    interactiveShellInit =
      ''
        set -g fish_key_bindings fish_vi_key_bindings
      '';
    functions = {
      fish_greeting = "${lib.getExe pkgs.fortune} -s | ${lib.getExe' pkgs.cowsay "cowsay"} -f (ls -1 ${pkgs.cowsay}/share/cowsay/cows/*.cow | shuf -n 1) | ${lib.getExe pkgs.lolcat} -t";
      normal_mode_by_default = {
        body = "set fish_bind_mode default";
        onEvent = "fish_prompt";
      };
    };
  };
  xdg.desktopEntries.fish = {
    name = "Fish";
    noDisplay = true;
  };
}
