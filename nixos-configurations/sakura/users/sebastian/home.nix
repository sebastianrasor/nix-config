{
  sebastianrasor = {
    core.enable = true;
    core.graphical = true;

    persistence.enable = true;
    prismlauncher.enable = true;
  };

  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "26.05";
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };
}
