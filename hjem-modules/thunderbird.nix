_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.thunderbird;
in
{
  options.sebastianrasor.thunderbird = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = with pkgs; [
      thunderbird
    ];

    sebastianrasor.persistence.directories = [ "${config.directory}/.thunderbird" ];
  };
}
