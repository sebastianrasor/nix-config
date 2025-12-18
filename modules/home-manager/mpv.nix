{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.mpv;
in
{
  options.sebastianrasor.mpv = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mpv.enable = true;
  };
}
