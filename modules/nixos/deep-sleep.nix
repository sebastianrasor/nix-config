{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.deep-sleep;
in
{
  options.sebastianrasor.deep-sleep = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [ "mem_sleep_default=deep" ];
  };
}
