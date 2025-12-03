{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.suspend-fix;
in
{
  options.sebastianrasor.suspend-fix = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    # https://github.com/systemd/systemd/issues/37370
    systemd.services = {
      systemd-hibernate.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0";
      systemd-suspend.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0";
      systemd-suspend-then-hibernate.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0";
    };
  };
}
