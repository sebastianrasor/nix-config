{ ... }:
{
  sebastianrasor = {
    core.enable = true;
    core.graphical = true;

    auto-rotate.enable = true;
    persistence.enable = true;
  };

  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "25.11";
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };
}
