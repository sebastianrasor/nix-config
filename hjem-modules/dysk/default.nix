_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.dysk;
in
{
  options.sebastianrasor.dysk = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = with pkgs; [
      dysk
    ];

    xdg.config.files."fish/conf.d/dysk.fish" = lib.mkIf config.sebastianrasor.fish.enable {
      source = ./dysk.fish;
    };
  };
}
