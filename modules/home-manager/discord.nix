{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.discord;
in
{
  options.sebastianrasor.discord = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      discord
    ];
    sebastianrasor.persistence.directories = [ "${config.xdg.configHome}/discord" ];
  };
}
