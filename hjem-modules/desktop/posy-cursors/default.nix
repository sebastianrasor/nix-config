_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.posy-cursors;
  theme = "Posy_Cursor_125_175";
in
{
  options.sebastianrasor.posy-cursors = {
    enable = lib.mkEnableOption "Posy's cursor theme";
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.posy-cursors
    ];

    environment.sessionVariables = {
      XCURSOR_SIZE = 32;
      XCURSOR_THEME = theme;
    };

    files = {
      ".Xresources".source = ./Xresources;
      ".icons/default/index.theme".source = ./index.theme;
      ".icons/${theme}".source = "${pkgs.posy-cursors}/share/icons/${theme}";
    };

    xdg.data.files = {
      "icons/default/index.theme".source = ./index.theme;
      "icons/${theme}".source = "${pkgs.posy-cursors}/share/icons/${theme}";
    };
  };
}
