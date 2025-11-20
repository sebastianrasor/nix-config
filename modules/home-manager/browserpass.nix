{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.browserpass.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.browserpass.enable {
    programs.browserpass.enable = true;
  };
}
