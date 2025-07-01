{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.yazi.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.yazi.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
