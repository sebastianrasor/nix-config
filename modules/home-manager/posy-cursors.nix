{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.posy-cursors.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.posy-cursors.enable {
    home.pointerCursor = {
      package = pkgs.posy-cursors;
      name = "Posy_Cursor_125_175";
      size = 32;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
