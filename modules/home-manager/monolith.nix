{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.monolith.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.monolith.enable {
    home.packages = [ pkgs.monolith ];
  };
}
