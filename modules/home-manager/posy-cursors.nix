{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.posy-cursors;
in
{
  options.sebastianrasor.posy-cursors = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      package = with pkgs; posy-cursors;
      name = "Posy_Cursor_125_175";
      size = 32;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
