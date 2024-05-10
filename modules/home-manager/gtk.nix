{ pkgs, ... }: {
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "adwaita-icon-theme";
    };
  };
}
