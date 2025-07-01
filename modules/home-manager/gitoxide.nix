{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.gitoxide.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.gitoxide.enable {
    home.packages = [pkgs.gitoxide];
  };
}
