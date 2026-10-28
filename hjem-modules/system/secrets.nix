_:
{
  lib,
  osConfig ? null,
  ...
}:
{
  options.sebastianrasor.secrets = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            path = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default =
                if osConfig != null && osConfig.sebastianrasor.secrets.enable then
                  osConfig.sops.secrets.${name}.path
                else
                  null;
              readOnly = true;
            };
          };
        }
      )
    );
  };
}
