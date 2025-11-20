{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.persistence.enable = lib.mkEnableOption "";
    sebastianrasor.persistence.storagePath = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist${config.home.homeDirectory}";
    };
  };

  config = lib.mkIf config.sebastianrasor.persistence.enable {
    home.persistence."${config.sebastianrasor.persistence.storagePath}" = {
      allowOther = true;
      directories = builtins.map (lib.strings.removePrefix config.home.homeDirectory) [
        config.xdg.stateHome
      ];
    };
  };
}
