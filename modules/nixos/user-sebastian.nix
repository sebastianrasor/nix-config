{ config, lib, ... }:
{
  options = {
    sebastianrasor.user-sebastian.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.user-sebastian.enable {
    home-manager.users.sebastian = import ../../configurations/home-manager/sebastian.nix;

    users.users.sebastian = {
      isNormalUser = true;
      home = "/home/sebastian";
      description = "Sebastian Rasor";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = lib.mkIf config.sebastianrasor.sshd.enable [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG71B1X8QTaPtldyB7UvST8bzYBLSyXHkKJG2BbT0tkG"
      ];
    };
  };
}
