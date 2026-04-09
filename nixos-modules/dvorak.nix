{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.dvorak;
in
{
  options.sebastianrasor.dvorak = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      xkb.layout = "dvorak";
    };

    console = {
      earlySetup = true;
      keyMap = "dvorak";
    };
  };
}
