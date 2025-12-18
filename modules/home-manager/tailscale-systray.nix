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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale-systray.enable = true;
  };
}
