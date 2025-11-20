{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.bat.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.bat.enable {
    programs.bat.enable = true;
    home.shellAliases.cat = "bat";
  };
}
