{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.printing;
in
{
  options.sebastianrasor.printing = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };
  };
}
