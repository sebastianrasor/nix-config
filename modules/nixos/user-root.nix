{ config, lib, ... }:
{
  options = {
    sebastianrasor.user-root.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.user-root.enable {
    home-manager.users.root = import ../../configurations/home-manager/root.nix;
  };
}
