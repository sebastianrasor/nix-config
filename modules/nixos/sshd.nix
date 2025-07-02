{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.sshd.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.sshd.enable {
    services.openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
