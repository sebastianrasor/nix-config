inputs@{
  constants,
  hjem,
  nixpkgs,
  pkgsFor ? { },
  self,
  ...
}:
let
  inherit (nixpkgs) lib;
  repoLib = import ../lib { inherit lib; };

  mkHjemOutput =
    pkgs: userConfig:
    let
      hjem-lib = import "${hjem}/lib.nix" { inherit lib pkgs; };
    in
    {
      manifest = {
        version = 3;
        files =
          lib.concatMap
            (lib.flip lib.pipe [
              builtins.attrValues
              (builtins.filter (x: x.enable))
              (map hjem-lib.fileToJson)
            ])
            [
              userConfig.files
              userConfig.xdg.cache.files
              userConfig.xdg.config.files
              userConfig.xdg.data.files
              userConfig.xdg.state.files
            ];
      };
      packages = map toString userConfig.packages;
    };

  nixosHjemConfigurations = lib.concatMapAttrs (
    hostname: nixosConfiguration:
    lib.mapAttrs' (
      username: userConfig:
      lib.nameValuePair "${username}@${hostname}" (mkHjemOutput nixosConfiguration.pkgs userConfig)
    ) (lib.filterAttrs (_: u: u.enable) nixosConfiguration.config.hjem.users)
  ) self.nixosConfigurations;

  standaloneHjemConfigurations = repoLib.readNixDir ./. (
    path:
    let
      name = lib.removeSuffix ".nix" (baseNameOf path);
      parts = lib.splitString "@" name;
      username = builtins.head parts;
      pkgsForSystem =
        system:
        pkgsFor.${system} or (import nixpkgs {
          inherit system;
          config = constants.nixConfig;
          overlays = builtins.attrValues self.overlays;
        });
      configurationModule = lib.modules.importApply path inputs;
      evaluated = lib.evalModules {
        specialArgs = {
          osConfig = null;
        };
        modules = [
          (
            { config, ... }:
            let
              pkgs = pkgsForSystem config.sebastianrasor.system;
            in
            {
              options.sebastianrasor.system = lib.mkOption {
                type = lib.types.str;
                default = "x86_64-linux";
              };

              config._module.args = {
                inherit pkgs;
                name = username;
                hjem-lib = import "${hjem}/lib.nix" { inherit lib pkgs; };
                utils = import "${nixpkgs}/nixos/lib/utils.nix" {
                  inherit lib pkgs;
                  config = {
                    systemd = {
                      package = pkgs.systemd;
                      globalEnvironment = { };
                    };
                  };
                };
              };
            }
          )
          "${hjem}/modules/common/user.nix"
          "${hjem}/modules/nixos/systemd.nix"
          {
            user = lib.mkDefault username;
            directory = lib.mkDefault "/home/${username}";
            clobberFiles = lib.mkDefault true;
          }
          configurationModule
        ]
        ++ lib.attrsets.attrValues self.hjemModules;
      };
    in
    mkHjemOutput (pkgsForSystem evaluated.config.sebastianrasor.system) evaluated.config
  );
in
nixosHjemConfigurations // standaloneHjemConfigurations
