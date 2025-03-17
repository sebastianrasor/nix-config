{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.dust.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.dust.enable {
    home.packages = [
      pkgs.dust
    ];
  };
}
