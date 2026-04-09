{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.dust;
in
{
  options.sebastianrasor.dust = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dust
    ];
  };
}
