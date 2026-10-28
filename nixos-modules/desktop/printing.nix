_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.printing;
in
{
  options.sebastianrasor.printing = {
    enable = lib.mkEnableOption "printing";
  };

  config = lib.mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
        cups-idprt-tspl
      ];
    };

    users.users.sebastian.extraGroups = [ "lp" ];
  };
}
