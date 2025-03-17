{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.thunderbird.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.thunderbird.enable {
    home.packages = [pkgs.thunderbird];
    # wtf??? programs.thunderbird.enable = true;
  };
}
