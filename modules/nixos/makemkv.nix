{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.makemkv.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.makemkv.enable {
    environment.systemPackages = [pkgs.makemkv];
    boot.kernelModules = ["sg"];
  };
}
