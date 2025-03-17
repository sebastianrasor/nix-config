{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.pass.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.pass.enable {
    programs.password-store.enable = true;
  };
}
