_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.bat;
in
{
  options.sebastianrasor.bat = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.bat
    ];

    xdg.config.files."fish/conf.d/bat.fish" = lib.mkIf config.sebastianrasor.fish.enable {
      source = ./bat.fish;
    };
  };
}
