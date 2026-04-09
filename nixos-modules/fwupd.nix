{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.fwupd;
in
{
  options.sebastianrasor.fwupd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.fwupd.enable = true;
  };
}
