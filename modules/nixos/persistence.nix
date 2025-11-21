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
    enable = lib.mkEnableOption "";
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
    # This is actually required for home-manager impermanence module:
    # https://github.com/nix-community/impermanence/blob/4b3e914cdf97a5b536a889e939fb2fd2b043a170/README.org#home-manager
    programs.fuse.userAllowOther = true;

    environment.persistence."${cfg.storagePath}" = {
      inherit (cfg) directories files;
      hideMounts = true;
    };
  };
}
