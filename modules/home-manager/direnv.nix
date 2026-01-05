{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.direnv;
in
{
  options.sebastianrasor.direnv = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
