{ ... }:
{
  sebastianrasor.core.enable = true;

  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "23.11";
  };

  programs.home-manager.enable = true;
}
