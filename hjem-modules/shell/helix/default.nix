_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.helix;
in
{
  options.sebastianrasor.helix = {
    enable = lib.mkEnableOption "Helix editor";
  };

  config = lib.mkIf cfg.enable {
    packages = [ pkgs.helix ];

    environment.sessionVariables = {
      EDITOR = lib.mkDefault "hx";
      VISUAL = lib.mkDefault "hx";
    };

    xdg.config.files."helix/config.toml".source = ./config.toml;
  };
}
