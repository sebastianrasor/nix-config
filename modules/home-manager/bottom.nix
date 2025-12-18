{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.bottom;
in
{
  options.sebastianrasor.bottom = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bottom.enable = true;
    home.shellAliases.top = "btm";
  };
}
