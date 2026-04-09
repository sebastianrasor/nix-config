{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.sane;
in
{
  options.sebastianrasor.sane = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.sane = {
      enable = true;
      brscan5.enable = true;
    };
  };
}
