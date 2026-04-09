{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.miniserve;
in
{
  options.sebastianrasor.miniserve = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      miniserve
    ];
  };
}
