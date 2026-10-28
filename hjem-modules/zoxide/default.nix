_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.zoxide;
in
{
  options.sebastianrasor.zoxide = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.zoxide
    ];

    xdg.config.files."fish/conf.d/zoxide.fish" = lib.mkIf config.sebastianrasor.fish.enable {
      source = ./zoxide.fish;
    };
  };
}
