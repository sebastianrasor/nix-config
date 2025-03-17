{...}: {
  sebastianrasor.core.enable = true;

  home = {
    username = "root";
    homeDirectory = "/root";
    keyboard.variant = "dvorak";

    stateVersion = "23.11";
  };

  programs.home-manager.enable = true;
}
