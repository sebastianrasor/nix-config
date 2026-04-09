{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.prismlauncher;
in
{
  options.sebastianrasor.prismlauncher = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      prismlauncher
    ];
  };
}
