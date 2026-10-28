_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.starship;
in
{
  options.sebastianrasor.starship = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.starship
    ];

    xdg.config.files = {
      "starship.toml".source = ./starship.toml;
      "fish/conf.d/starship.fish" = lib.mkIf config.sebastianrasor.fish.enable {
        source = ./starship.fish;
      };
    };
  };
}
