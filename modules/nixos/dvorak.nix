{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.dvorak.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.dvorak.enable {
    services.xserver = {
      xkb.layout = "dvorak";
    };

    console = {
      earlySetup = true;
      keyMap = "dvorak";
    };
  };
}
