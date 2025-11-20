{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.miniserve.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.miniserve.enable {
    home.packages = [ pkgs.miniserve ];
  };
}
