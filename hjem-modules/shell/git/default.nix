_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.git;
in
{
  options.sebastianrasor.git = {
    enable = lib.mkEnableOption "Git";
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.git
    ];

    xdg.config.files."git/config".source = ./config;
  };
}
