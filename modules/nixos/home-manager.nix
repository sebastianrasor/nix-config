{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.home-manager.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.home-manager.enable {
    environment.systemPackages = [pkgs.home-manager];
  };
}
