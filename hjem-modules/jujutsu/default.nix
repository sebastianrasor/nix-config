_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.jujutsu;
in
{
  options.sebastianrasor.jujutsu = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.jujutsu
    ];

    xdg.config.files."jj/config.toml".source = ./config.toml;
  };
}
