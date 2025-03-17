{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.bash.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.bash.enable {
    programs.bash.enable = true;
  };
}
