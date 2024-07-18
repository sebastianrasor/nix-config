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
  };

  imports = [
    outputs.homeManagerModules.bash
    outputs.homeManagerModules.fish
    outputs.homeManagerModules.git
    outputs.homeManagerModules.starship
    outputs.homeManagerModules.vim
    outputs.homeManagerModules.zoxide
  ];

  programs.home-manager.enable = true;
}
