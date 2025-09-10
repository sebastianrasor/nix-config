{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.sshd.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.sshd.enable {
    environment.persistence."${config.sebastianrasor.persistence.storagePath}".files = lib.mkIf config.sebastianrasor.persistence.enable [
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
    services.openssh = {
      enable = true;
      openFirewall = false;
      # I'm larping as someone important
      # This might be actually useful, though:
      # https://linux-audit.com/the-real-purpose-of-login-banners-on-linux/
      banner = ''
        You are accessing a private Information System (IS) that is provided for
        owner-authorized use only. By using this IS (which includes any device attached
        to this IS), you consent to the following conditions:

        -The IS owner routinely intercepts and monitors communications on this IS.

        -At any time, the IS owner may inspect and seize data stored on this IS.

        -Communications using, or data stored on, this IS are not private, are subject
        to routine monitoring, interception, and search, and may be disclosed or used
        for any owner-authorized purpose.

        -This IS includes security measures (e.g., authentication and access controls)
        to protect the IS owner's interests--not for your personal benefit or privacy.

      '';
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        UseDns = true;
      };
    };

    specialisation.expose-ssh.configuration = {
      services.openssh = {
        openFirewall = lib.mkForce true;
        settings.PermitRootLogin = lib.mkForce "prohibit-password";
      };
      users.users.root = {
        shell = lib.mkForce pkgs.bash;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG71B1X8QTaPtldyB7UvST8bzYBLSyXHkKJG2BbT0tkG"
        ];
      };
    };
  };
}
