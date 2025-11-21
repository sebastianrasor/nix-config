{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.prismlauncher.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.prismlauncher.enable {
    home.packages = [ pkgs.prismlauncher ];
    sebastianrasor.persistence.directories = [ "${config.xdg.dataHome}/PrismLauncher" ];
  };
}
