{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.navi.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.navi.enable {
    programs.navi = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
