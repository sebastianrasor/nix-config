{ config, lib, ... }:
{
  options = {
    sebastianrasor.bottom.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.bottom.enable {
    programs.bottom.enable = true;
    home.shellAliases.top = "btm";
  };
}
