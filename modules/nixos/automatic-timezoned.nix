{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.automatic-timezoned;
in
{
  options.sebastianrasor.automatic-timezoned = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.automatic-timezoned.enable = true;
  };
}
