inputs@{
  constants,
  hjem,
  nixpkgs,
  self,
  ...
}:
let
  inherit (nixpkgs) lib;
in
lib.pipe ./. [
  builtins.readDir
  builtins.attrNames
  (builtins.filter (name: name != "default.nix"))
  (map (
    entry:
    let
      name = lib.removeSuffix ".nix" entry;
      parts = lib.splitString "@" name;
      username = builtins.head parts;
      hostname = if builtins.length parts > 1 then builtins.elemAt parts 1 else null;
      pkgs =
        if hostname != null && self.nixosConfigurations ? ${hostname} then
          self.nixosConfigurations.${hostname}.pkgs
        else
          import nixpkgs {
            system = "x86_64-linux";
            config = constants.nixConfig;
            overlays = builtins.attrValues self.overlays;
          };
      osConfig =
        if hostname != null && self.nixosConfigurations ? ${hostname} then
          self.nixosConfigurations.${hostname}.config
        else
          null;
      utils = import "${nixpkgs}/nixos/lib/utils.nix" {
        inherit lib pkgs;
        config =
          if osConfig != null then
            osConfig
          else
            {
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
            osConfig
            pkgs
            utils
            ;
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
      value = {
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
                evaluated.config.files
                evaluated.config.xdg.cache.files
                evaluated.config.xdg.config.files
                evaluated.config.xdg.data.files
                evaluated.config.xdg.state.files
              ];
        };
        packages = map toString evaluated.config.packages;
      };
    }
  ))
  builtins.listToAttrs
]
