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
    programs.password-store = {
      enable = true;
      settings.PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
    };
    sebastianrasor.persistence.directories = [
      config.programs.password-store.settings.PASSWORD_STORE_DIR
    ];
  };
}
