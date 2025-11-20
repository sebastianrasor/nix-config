{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.avahi.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.avahi.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };
  };
}
