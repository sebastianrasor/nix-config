{ pkgs, ... }: {
  xdg.desktopEntries.nixos-manual = {
    name = "NixOS Manual";
    noDisplay = true;
  };
}
