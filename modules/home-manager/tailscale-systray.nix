{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.tailscale-systray;
in
{
  options.sebastianrasor.tailscale-systray = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale-systray.enable = true;
  };
}
