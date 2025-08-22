{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.discord.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.discord.enable {
    home.packages = [pkgs.discord];
    home.persistence."${config.sebastianrasor.persistence.storagePath}".directories = lib.mkIf config.sebastianrasor.persistence.enable (builtins.map (lib.strings.removePrefix config.home.homeDirectory) ["${config.xdg.configHome}/discord"]);
  };
}
