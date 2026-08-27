_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.solaar;
in
{
  options.sebastianrasor.solaar = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.solaar.enable = true;
  };
}
