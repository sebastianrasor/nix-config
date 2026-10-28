_:
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
    packages = [
      pkgs.posy-cursors
    ];

    environment.sessionVariables = {
      XCURSOR_SIZE = 32;
      XCURSOR_THEME = "Posy_Cursor_125_175";
    };

    files = {
      ".Xresources".source = ./Xresources;
      ".icons/default/index.theme".source = ./index.theme;
      ".icons/Posy_Cursor_125_175".source = "${pkgs.posy-cursors}/share/icons/Posy_Cursor_125_175";
    };

    xdg.data.files = {
      "icons/default/index.theme".source = ./index.theme;
      "icons/Posy_Cursor_125_175".source = "${pkgs.posy-cursors}/share/icons/Posy_Cursor_125_175";
    };
  };
}
