{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.dysk;
in
{
  options.sebastianrasor.dysk = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dysk
    ];

    programs.fish.shellAbbrs."df" = "dysk";
  };
}
