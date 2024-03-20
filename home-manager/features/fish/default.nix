{ pkgs, ... }: {
  home.packages = with pkgs; [
    cowsay
    fish
    fortune
    lolcat
  ];
  programs.fish = {
    enable = true;
    loginShellInit =
      ''
        if [ "$(tty)" = "/dev/tty1" ]; and [ -z "$WAYLAND_DISPLAY" ];
          exec Hyprland;
        end
      '';
    functions = {
      fish_greeting = "${pkgs.fortune}/bin/fortune | ${pkgs.cowsay}/bin/cowsay -f (ls ${pkgs.cowsay}/share/cowsay/cows/*.cow | shuf -n 1) | ${pkgs.lolcat}/bin/lolcat";
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
