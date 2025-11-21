{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.thunderbird.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.thunderbird.enable {
    home.packages = [ pkgs.thunderbird ];
    sebastianrasor.persistence.directories = [ "${config.home.homeDirectory}/.thunderbird" ];
    # wtf??? programs.thunderbird.enable = true;
  };
}
