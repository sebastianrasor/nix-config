_:
{
  config,
  lib,
  ...
}:
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
      apply = map (
        lib.attrsets.updateManyAttrsByPath [
          {
            path = [ "directory" ];
            update = lib.strings.removePrefix config.directory;
          }
        ]
      );
    };

    files = lib.mkOption {
      type = lib.types.listOf (lib.types.coercedTo lib.types.str (f: { file = f; }) lib.types.attrs);
      default = [ ];
      apply = map (
        lib.attrsets.updateManyAttrsByPath [
          {
            path = [ "file" ];
            update = lib.strings.removePrefix config.directory;
          }
        ]
      );
    };
  };
}
