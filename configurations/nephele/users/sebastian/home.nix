{...}: {
  sebastianrasor.core.enable = true;

  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
