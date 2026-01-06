{ ... }:
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

    stateVersion = "23.11";
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };
}
