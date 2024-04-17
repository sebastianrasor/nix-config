{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "23.11";

    packages = with pkgs; [
      discord
      dtach
      google-chrome
      yubioath-flutter
    ];
  };

  imports = [
    outputs.homeManagerModules.atkinson-hyperlegible-font
    outputs.homeManagerModules.bash
    outputs.homeManagerModules.beets
    outputs.homeManagerModules.bemenu
    outputs.homeManagerModules.bibata-cursors
    outputs.homeManagerModules.brillo
    outputs.homeManagerModules.browserpass
    outputs.homeManagerModules.dark
    outputs.homeManagerModules.fish
    outputs.homeManagerModules.foot
    outputs.homeManagerModules.git
    outputs.homeManagerModules.gpg
    outputs.homeManagerModules.grimblast
    outputs.homeManagerModules.gtk
    outputs.homeManagerModules.hypridle
    outputs.homeManagerModules.hyprland
    outputs.homeManagerModules.hyprlock
    outputs.homeManagerModules.hyprpaper
    outputs.homeManagerModules.hyprpicker
    outputs.homeManagerModules.mako
    outputs.homeManagerModules.mpc
    outputs.homeManagerModules.mpd
    outputs.homeManagerModules.pass
    outputs.homeManagerModules.pinentry-custom
    outputs.homeManagerModules.playerctl
    outputs.homeManagerModules.qt
    outputs.homeManagerModules.starship
    outputs.homeManagerModules.unfree-packages
    outputs.homeManagerModules.vim
    outputs.homeManagerModules.waybar
    outputs.homeManagerModules.xdg-user-dirs
    outputs.homeManagerModules.zoxide
  ];

  programs.home-manager.enable = true;
}
