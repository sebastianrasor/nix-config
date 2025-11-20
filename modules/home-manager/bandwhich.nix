{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.bandwhich.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.bandwhich.enable {
    home.packages = [ pkgs.bandwhich ];
  };
}
