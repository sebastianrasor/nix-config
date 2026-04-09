{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.google-chrome;
in
{
  options.sebastianrasor.google-chrome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      google-chrome
    ];
    sebastianrasor.persistence.directories = [ "${config.xdg.configHome}/google-chrome" ];
  };
}
