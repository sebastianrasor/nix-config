{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.jq;
in
{
  options.sebastianrasor.jq = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.jq.enable = true;
  };
}
