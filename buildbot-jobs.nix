{ nixpkgs, self, ... }:
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
    (nixosConfiguration.extendModules {
      modules = [
        {
          nixpkgs.buildPlatform = system;
        }
      ];
    }).config.system.build.toplevel
  ) self.nixosConfigurations;

  packages = builtins.mapAttrs (
    targetSystem: packages:
    let
      newPkgs = import nixpkgs {
        crossSystem = targetSystem;
        localSystem = system;
        overlays = builtins.attrValues self.overlays;
      };
    in
    if (compatibleCrossBuild system targetSystem) then
      lib.pipe packages [
        (builtins.mapAttrs (
          packageName: package: package.override (oldArgs: builtins.intersectAttrs oldArgs newPkgs)
        ))
      ]
    else
      { }
  ) self.packages;
})
