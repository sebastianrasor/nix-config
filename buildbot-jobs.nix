{ nixpkgs, self, ... }:
let
  supportedSystems = [
    "x86_64-linux"
  ];
  eachSupportedSystem = nixpkgs.lib.genAttrs supportedSystems;

  packages = eachSupportedSystem (
    system: nixpkgs.lib.mapAttrs' (n: nixpkgs.lib.nameValuePair "package-${n}") self.packages.${system}
  );
  legacyPackages =
    let
      inherit (nixpkgs) lib;
      nameValuePair = path: value: {
        inherit value;
        name = "legacyPackage-${lib.last path}";
      };
      recurseForDerivations =
        _: value: (builtins.isAttrs value && value ? recurseForDerivations && value.recurseForDerivations);
      optionalDerivation = path: value: lib.optional (lib.isDerivation value) (nameValuePair path value);
    in
    eachSupportedSystem (
      system:
      # Shamelessly stolen from here:
      # https://github.com/liquidnya/infrastructure/blob/7441244acb50625da2d9221308bf1ce0581197ec/packages/default.nix#L9-L24
      nixpkgs.lib.pipe self.legacyPackages.${system} [
        (nixpkgs.lib.mapAttrsToListRecursiveCond recurseForDerivations optionalDerivation)
        (nixpkgs.lib.concatMap nixpkgs.lib.id)
        builtins.listToAttrs
      ]
    );
  checks = nixpkgs.lib.pipe self.nixosConfigurations [
    (nixpkgs.lib.mapAttrsToList (
      name: nixosConfiguration: {
        path = [
          nixosConfiguration.config.nixpkgs.hostPlatform.system
          "nixosConfiguration-${name}"
        ];
        update = _: nixosConfiguration.config.system.build.toplevel;
      }
    ))
    nixpkgs.lib.updateManyAttrsByPath
  ] { };
in
builtins.foldl' nixpkgs.lib.recursiveUpdate { } [
  checks
  legacyPackages
  packages
]
