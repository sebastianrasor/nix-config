{ pkgs, ... }: {
  xdg.desktopEntries.cups = {
    name = "Manage Printing";
    noDisplay = true;
  };
}
