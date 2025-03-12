{ config, lib, ... }:
{
  options = {
    sebastianrasor.zoxide.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.zoxide.enable {
    programs.zoxide.enable = true;
  };
}
