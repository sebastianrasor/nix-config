{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.dog;
in
{
  options.sebastianrasor.dog = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dogdns
    ];

    programs.fish.shellAbbrs."dig" = "dog";
  };
}
