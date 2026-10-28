_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.sane;
in
{
  options.sebastianrasor.sane = {
    enable = lib.mkEnableOption "SANE";
  };

  config = lib.mkIf cfg.enable {
    hardware.sane = {
      enable = true;
      brscan5.enable = true;
    };

    users.users.sebastian.extraGroups = [ "scanner" ];
  };
}
