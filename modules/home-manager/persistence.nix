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
    enable = lib.mkEnableOption "";
    storagePath = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist${config.home.homeDirectory}";
    };
    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.coercedTo lib.types.str (d: { directory = d; }) lib.types.attrs);
      default = [ ];
      apply = map (
        lib.attrsets.updateManyAttrsByPath [
          {
            path = [ "directory" ];
            update = lib.strings.removePrefix config.home.homeDirectory;
          }
        ]
      );
    };
    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      apply = map (lib.strings.removePrefix config.home.homeDirectory);
    };
  };

  config = lib.mkIf cfg.enable {
    home.persistence."${cfg.storagePath}" = {
      inherit (cfg) directories files;
      allowOther = true;
    };
  };
}
