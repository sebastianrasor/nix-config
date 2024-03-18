{ inputs, outputs, config, pkgs, lib, ... }:

{
  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "23.11";

    #packages = with pkgs; [
    #  discord
    #  google-chrome
    #];
  };

  imports = [
    ../../features/bash
    ../../features/fish
    ../../features/git
    ../../features/gpg
    ../../features/pass
    ../../features/starship
    ../../features/unfree-packages
    ../../features/vim
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
