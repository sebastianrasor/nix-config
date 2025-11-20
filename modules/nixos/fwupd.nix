{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.fwupd.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.fwupd.enable {
    services.fwupd.enable = true;
  };
}
