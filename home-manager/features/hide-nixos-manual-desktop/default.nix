{ pkgs, ... }: {
  xdg.desktopEntries.nixos-manual = {
    name = "Hidden";
    noDisplay = true;
  };
}
