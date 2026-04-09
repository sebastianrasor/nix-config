{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.navi;
in
{
  options.sebastianrasor.navi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.navi = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
