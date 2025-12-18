{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.systemd-timesyncd;
in
{
  options.sebastianrasor.systemd-timesyncd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.timesyncd = {
      enable = true;
      servers = [ ];
      fallbackServers = [ "time.google.com" ];
    };
  };
}
