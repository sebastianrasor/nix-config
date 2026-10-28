_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.pass;
in
{
  options.sebastianrasor.pass = {
    enable = lib.mkEnableOption "pass";

    passwordStoreDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.xdg.data.directory}/password-store";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.pass
    ];

    environment.sessionVariables.PASSWORD_STORE_DIR = cfg.passwordStoreDir;
  };
}
