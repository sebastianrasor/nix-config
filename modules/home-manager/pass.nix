{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.pass;
in
{
  options.sebastianrasor.pass = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    passwordStoreDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.xdg.dataHome}/password-store";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.password-store = {
      enable = true;
      settings.PASSWORD_STORE_DIR = cfg.passwordStoreDir;
    };

    sebastianrasor.persistence.directories = [ cfg.passwordStoreDir ];
  };
}
