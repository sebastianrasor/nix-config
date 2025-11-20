{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.tokei.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.tokei.enable {
    home.packages = [ pkgs.tokei ];
  };
}
