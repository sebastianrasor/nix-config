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
  legacyPackages = builtins.mapAttrs (
    targetSystem: legacyPackages:
    let
      newPkgs = import nixpkgs {
        crossSystem = targetSystem;
        localSystem = system;
      };
      nameValuePair = path: value: {
        name = "legacyPackage-${lib.last path}";
        value = value.override (oldArgs: builtins.intersectAttrs oldArgs newPkgs);
      };
      recurseForDerivations =
        _: value: (builtins.isAttrs value && value ? recurseForDerivations && value.recurseForDerivations);
      optionalDerivation = path: value: lib.optional (lib.isDerivation value) (nameValuePair path value);
    in
    if (compatibleCrossBuild system targetSystem) then
      # Shamelessly stolen from here:
      # https://github.com/liquidnya/infrastructure/blob/7441244acb50625da2d9221308bf1ce0581197ec/packages/default.nix#L9-L24
      nixpkgs.lib.pipe legacyPackages [
        (nixpkgs.lib.mapAttrsToListRecursiveCond recurseForDerivations optionalDerivation)
        (nixpkgs.lib.concatMap nixpkgs.lib.id)
        builtins.listToAttrs
      ]
    else
      { }
  ) self.legacyPackages;

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
