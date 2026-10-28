{
  constants,
  nixpkgs,
  pkgsFor,
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

  packageNames = lib.pipe ./packages [
    builtins.readDir
    builtins.attrNames
    (builtins.filter (name: name != "default.nix"))
    (map (lib.removeSuffix ".nix"))
  ];
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
      crossPackages = lib.pipe packageNames [
        (builtins.filter (
          packageName: lib.meta.availableOn { system = targetSystem; } pkgsFor.${system}.${packageName}
        ))
        (map (packageName: {
          name = packageName;
          value = newPkgs.${packageName};
        }))
        builtins.listToAttrs
      ];
    in
    if targetSystem == system then
      packages
    else if (compatibleCrossBuild system targetSystem) then
      crossPackages
    else
      { }
  ) self.packages;
})
