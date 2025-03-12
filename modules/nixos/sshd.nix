{ config, lib, ... }:
{
  options = {
    sebastianrasor.sshd.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.sshd.enable {
    services.openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    security.pam.sshAgentAuth.enable = true;

    users.users."root".openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG71B1X8QTaPtldyB7UvST8bzYBLSyXHkKJG2BbT0tkG"
    ];
  };
}
