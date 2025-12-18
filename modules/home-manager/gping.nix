{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.gping;
in
{
  options.sebastianrasor.gping = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      gping
    ];
  };
}
