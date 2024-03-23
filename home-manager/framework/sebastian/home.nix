{ inputs, outputs, config, pkgs, lib, ... }:

{
  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "23.11";

    packages = with pkgs; [
      discord
      google-chrome
      yubioath-flutter
    ];
  };

  imports = [
    ../../features/atkinson-hyperlegible-font
    ../../features/bash
    ../../features/beets
    ../../features/bemenu
    ../../features/bibata-cursors
    ../../features/brillo
    ../../features/dark
    ../../features/fish
    ../../features/foot
    ../../features/git
    ../../features/gpg
    ../../features/grimblast
    ../../features/gtk
    ../../features/hypridle
    ../../features/hyprland
    ../../features/hyprlock
    ../../features/hyprpaper
    ../../features/hyprpicker
    ../../features/mako
    ../../features/mpd
    ../../features/ncmpcpp
    ../../features/pass
    ../../features/pinentry-custom
    ../../features/playerctld
    ../../features/qt
    ../../features/starship
    ../../features/unfree-packages
    ../../features/vim
    ../../features/waybar
    ../../features/xdg-user-dirs
    ../../features/zoxide
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
  };

  programs.home-manager.enable = true;
}
