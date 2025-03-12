{ ... }:
{
  sebastianrasor.core.enable = true;

  home = {
    username = "root";
    homeDirectory = "/root";
    keyboard.variant = "dvorak";

    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
