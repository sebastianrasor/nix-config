{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.bat;
in
{
  options.sebastianrasor.bat = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bat.enable = true;

    programs.fish.shellAbbrs."cat" = "bat";
  };
}
