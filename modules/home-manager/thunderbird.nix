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

  # TODO: Use programs.thunderbird.* to declaratively configure thunderbird.
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      thunderbird
    ];

    sebastianrasor.persistence.directories = [ "${config.home.homeDirectory}/.thunderbird" ];
  };
}
