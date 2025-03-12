{ config, lib, ... }:
{
  options = {
    sebastianrasor.core.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.core.enable {
    sebastianrasor.i18n.enable = true;
    sebastianrasor.networkmanager.enable = true;
    sebastianrasor.nix.enable = true;
  };
}
