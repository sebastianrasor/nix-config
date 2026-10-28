{
  constants,
  nixpkgs,
  self,
  ...
}:
let
  inherit (nixpkgs) lib;

  # This workaround won't work if I ever add a buildbot worker that isn't x86_64-linux
  # https://github.com/nix-community/buildbot-nix/issues/302
  #supportedSystems = nixpkgs.lib.systems.flakeExposed;
  supportedSystems = [ "x86_64-linux" ];

  compatibleCrossBuild =
    let
      inherit (lib.systems.inspect.predicates) isDarwin;
      inherit (lib.systems.parse) mkSystemFromString;
    in
    localSystem: crossSystem:
    isDarwin (mkSystemFromString localSystem) == isDarwin (mkSystemFromString crossSystem);
in
lib.genAttrs supportedSystems (system: {
  nixosConfigurations = builtins.mapAttrs (
    _: nixosConfiguration:
    (
      if nixosConfiguration.pkgs.stdenv.buildPlatform.system == system then
        nixosConfiguration
      else
        nixosConfiguration.extendModules {
          modules = [
            {
              nixpkgs.buildPlatform = system;
            }
          ];
        }
    ).config.system.build.toplevel
  ) self.nixosConfigurations;

  packages = builtins.mapAttrs (
    targetSystem: packages:
    let
      newPkgs = import nixpkgs {
        config = constants.nixConfig;
        crossSystem = targetSystem;
        localSystem = system;
        overlays = builtins.attrValues self.overlays;
      };
    in
    if targetSystem == system then
      packages
    else if (compatibleCrossBuild system targetSystem) then
      builtins.mapAttrs (packageName: _: newPkgs.${packageName}) packages
    else
      { }
  ) self.packages;
})
