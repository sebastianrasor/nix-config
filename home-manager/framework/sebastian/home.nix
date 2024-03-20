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
    ];
  };

  imports = [
    ../../features/atkinson-hyperlegible-font
    ../../features/bash
    ../../features/bemenu
    ../../features/bibata-cursors
    ../../features/fish
    ../../features/foot
    ../../features/git
    ../../features/gpg
    ../../features/hide-cups-desktop
    ../../features/hide-nixos-manual-desktop
    ../../features/hyprland
    ../../features/mako
    ../../features/pass
    ../../features/starship
    ../../features/unfree-packages
    ../../features/vim
    ../../features/waybar
    ../../features/wpaperd
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
