{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.ripgrep;
in
{
  options.sebastianrasor.ripgrep = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ripgrep.enable = true;
  };
}
