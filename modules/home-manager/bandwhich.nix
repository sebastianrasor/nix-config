{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.bandwhich;
in
{
  options.sebastianrasor.bandwhich = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bandwhich
    ];
  };
}
