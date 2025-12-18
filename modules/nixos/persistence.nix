{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.sebastianrasor.persistence;
in
{
  options.sebastianrasor.persistence = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

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

  config = lib.mkIf cfg.enable {
    environment.persistence."${cfg.storagePath}" = {
      inherit (cfg) directories files;
      hideMounts = true;
    };
  };
}
