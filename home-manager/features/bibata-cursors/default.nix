{ pkgs, ... }: {
  home.packages = with pkgs; [ bibata-cursors ];
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };
}
