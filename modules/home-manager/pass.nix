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
    sebastianrasor.persistence.directories = [
      config.programs.password-store.settings.PASSWORD_STORE_DIR
    ];
  };
}
