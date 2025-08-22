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
    home.persistence."${config.sebastianrasor.persistence.storagePath}".directories = lib.mkIf config.sebastianrasor.persistence.enable (builtins.map (lib.strings.removePrefix config.home.homeDirectory) ["${config.home.homeDirectory}/.thunderbird"]);
    # wtf??? programs.thunderbird.enable = true;
  };
}
