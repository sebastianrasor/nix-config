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
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    services.timesyncd = {
      enable = true;
      servers = [ ];
      fallbackServers = [ "time.google.com" ];
    };
  };
}
