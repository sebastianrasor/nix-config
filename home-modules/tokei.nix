{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.tokei;
in
{
  options.sebastianrasor.tokei = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      tokei
    ];
  };
}
