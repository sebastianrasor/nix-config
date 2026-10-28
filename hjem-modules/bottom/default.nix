_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.bottom;
in
{
  options.sebastianrasor.bottom = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.bottom
    ];

    xdg.config.files."fish/conf.d/bottom.fish" = lib.mkIf config.sebastianrasor.fish.enable {
      source = ./bottom.fish;
    };
  };
}
