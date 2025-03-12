{ config, lib, ... }:
{
  options = {
    sebastianrasor.ripgrep.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.ripgrep.enable {
    programs.ripgrep.enable = true;
  };
}
