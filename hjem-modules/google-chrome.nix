_:
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
    packages = with pkgs; [
      google-chrome
    ];
    sebastianrasor.persistence.directories = [ "${config.xdg.config.directory}/google-chrome" ];
  };
}
