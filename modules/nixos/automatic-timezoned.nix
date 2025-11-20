{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.automatic-timezoned.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.automatic-timezoned.enable {
    services.automatic-timezoned.enable = true;
  };
}
