{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.sudo-rs;
in
{
  options.sebastianrasor.sudo-rs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    security.sudo-rs.enable = true;
  };
}
