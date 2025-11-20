{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.pass.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.pass.enable {
    programs.password-store.enable = true;
    home.persistence."${config.sebastianrasor.persistence.storagePath}".directories =
      lib.mkIf config.sebastianrasor.persistence.enable
        (
          builtins.map (lib.strings.removePrefix config.home.homeDirectory) [
            config.programs.password-store.settings.PASSWORD_STORE_DIR
          ]
        );
  };
}
