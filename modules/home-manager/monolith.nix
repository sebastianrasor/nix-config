{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.monolith;
in
{
  options.sebastianrasor.monolith = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      monolith
    ];
  };
}
