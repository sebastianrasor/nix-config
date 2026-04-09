{
  config,
  constants,
  lib,
  outputs,
  ...
}:
let
  cfg = config.sebastianrasor.nixpkgs;
in
{
  options.sebastianrasor.nixpkgs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs = {
      config = constants.nixConfig;
      overlays = builtins.attrValues outputs.overlays;
    };
  };
}
