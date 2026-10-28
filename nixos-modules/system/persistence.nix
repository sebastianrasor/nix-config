{ impermanence, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.persistence;
in
{
  options.sebastianrasor.persistence = {
    enable = lib.mkEnableOption "persistence";

    storagePath = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist";
    };

    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.coercedTo lib.types.str (d: { directory = d; }) lib.types.attrs);
      default = [ ];
    };

    files = lib.mkOption {
      type = lib.types.listOf (lib.types.coercedTo lib.types.str (f: { file = f; }) lib.types.attrs);
      default = [ ];
    };
  };

  imports = [
    impermanence.nixosModules.impermanence
  ];

  config = lib.mkIf cfg.enable {
    environment.persistence = lib.mkMerge (
      [
        {
          "${cfg.storagePath}" = {
            inherit (cfg) directories files;
            hideMounts = true;
          };
        }
      ]
      ++ lib.mapAttrsToList (
        username: userCfg:
        let
          pCfg = userCfg.sebastianrasor.persistence;
        in
        lib.mkIf (userCfg.enable && pCfg.enable) {
          "${pCfg.storagePath}" = {
            hideMounts = true;
            users.${username} = {
              inherit (pCfg) directories files;
            };
          };
        }
      ) config.hjem.users
    );
  };
}
