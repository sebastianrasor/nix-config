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

  standaloneHjemConfigurations = lib.pipe ./. [
    builtins.readDir
    builtins.attrNames
    (builtins.filter (name: name != "default.nix"))
    (map (
      entry:
      let
        name = lib.removeSuffix ".nix" entry;
        parts = lib.splitString "@" name;
        username = builtins.head parts;
        pkgs =
          pkgsFor.x86_64-linux or (import nixpkgs {
            system = "x86_64-linux";
            config = constants.nixConfig;
            overlays = builtins.attrValues self.overlays;
          });
        utils = import "${nixpkgs}/nixos/lib/utils.nix" {
          inherit lib pkgs;
          config = {
            systemd = {
              package = pkgs.systemd;
              globalEnvironment = { };
            };
          };
        };
        hjem-lib = import "${hjem}/lib.nix" { inherit lib pkgs; };
        configurationModule = lib.modules.importApply ./${entry} inputs;
        evaluated = lib.evalModules {
          specialArgs = {
            inherit
              hjem-lib
              pkgs
              utils
              ;
            osConfig = null;
          };
          modules = [
            "${hjem}/modules/common/user.nix"
            "${hjem}/modules/nixos/systemd.nix"
            {
              _module.args.name = username;
              user = lib.mkDefault username;
              directory = lib.mkDefault "/home/${username}";
              clobberFiles = lib.mkDefault true;
            }
            configurationModule
          ]
          ++ lib.attrsets.attrValues self.hjemModules;
        };
      in
      {
        inherit name;
        value = mkHjemOutput pkgs evaluated.config;
      }
    ))
    builtins.listToAttrs
  ];
in
nixosHjemConfigurations // standaloneHjemConfigurations
