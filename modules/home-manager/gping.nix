{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.gping.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.gping.enable {
    home.packages = [ pkgs.gping ];
  };
}
