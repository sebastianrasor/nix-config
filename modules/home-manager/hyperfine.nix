{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.hyperfine;
in
{
  options.sebastianrasor.hyperfine = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      hyperfine
    ];
  };
}
