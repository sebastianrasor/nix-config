{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.gitoxide;
in
{
  options.sebastianrasor.gitoxide = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      gitoxide
    ];
  };
}
