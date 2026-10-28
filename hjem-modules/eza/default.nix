_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.eza;
in
{
  options.sebastianrasor.eza = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.eza
    ];

    xdg.config.files."fish/conf.d/eza.fish" = lib.mkIf config.sebastianrasor.fish.enable {
      source = ./eza.fish;
    };
  };
}
