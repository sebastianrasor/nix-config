{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.yazi;
in
{
  options.sebastianrasor.yazi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
