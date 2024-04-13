{ lib, pkgs, ... }: {
  programs.fish = {
    enable = true;
    loginShellInit =
      ''
        if [ "$(tty)" = "/dev/tty1" ]; and [ -z "$WAYLAND_DISPLAY" ];
          exec Hyprland;
        end
      '';
    functions = {
      fish_greeting = "${lib.getExe pkgs.fortune} -s | ${lib.getExe' pkgs.cowsay "cowsay"} -f (ls -1 ${pkgs.cowsay}/share/cowsay/cows/*.cow | shuf -n 1) | ${lib.getExe pkgs.lolcat} -t";
    };
    shellAbbrs = {
      vhm = "vim ~/.config/home-manager/home.nix";
      vnix = "sudo vim /etc/nixos/configuration.nix";
      hms = "home-manager switch";
      nrs = "sudo nixos-rebuild switch";
    };
  };
  xdg.desktopEntries.fish = {
    name = "Fish";
    noDisplay = true;
  };
}
