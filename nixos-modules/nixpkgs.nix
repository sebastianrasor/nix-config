{
  constants,
  nixpkgs,
  pkgsFor ? nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
    system:
    import nixpkgs {
      inherit system;
      config = constants.nixConfig;
      overlays = builtins.attrValues self.overlays;
    }
  ),
  self,
  ...
}:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.nixpkgs;
  isCross = config.nixpkgs.buildPlatform != config.nixpkgs.hostPlatform;
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
      overlays = builtins.attrValues self.overlays;
    };

    _module.args.pkgs = lib.mkIf (!isCross) (lib.mkForce pkgsFor.${config.nixpkgs.hostPlatform.system});
  };
}
