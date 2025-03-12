{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.mpv.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.mpv.enable {
    programs.mpv.enable = true;
  };
}
