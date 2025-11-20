{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.zoxide.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.zoxide.enable {
    programs.zoxide.enable = true;
    home.persistence."${config.sebastianrasor.persistence.storagePath}".directories =
      lib.mkIf config.sebastianrasor.persistence.enable
        (
          builtins.map (lib.strings.removePrefix config.home.homeDirectory) [
            "${config.xdg.dataHome}/zoxide"
          ]
        );
  };
}
