{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.jnv;
in
{
  options.sebastianrasor.jnv = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      jnv
    ];
  };
}
