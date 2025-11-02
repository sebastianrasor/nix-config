{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.prismlauncher.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.prismlauncher.enable {
    home.packages = [pkgs.prismlauncher];
    home.persistence."${config.sebastianrasor.persistence.storagePath}".directories = lib.mkIf config.sebastianrasor.persistence.enable (builtins.map (lib.strings.removePrefix config.home.homeDirectory) ["${config.xdg.stateHome}/PrismLauncher"]);
  };
}
