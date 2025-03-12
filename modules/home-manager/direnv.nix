{ config, lib, ... }:
{
  options = {
    sebastianrasor.direnv.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.direnv.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
