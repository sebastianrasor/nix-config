{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.core.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.core.enable {
    sebastianrasor.automatic-timezoned.enable = true;
    sebastianrasor.home-manager.enable = true;
    sebastianrasor.i18n.enable = true;
    sebastianrasor.nix.enable = true;
    sebastianrasor.pam.enable = true;
    sebastianrasor.secrets.enable = true;
    sebastianrasor.sshd.enable = true;
    sebastianrasor.sudo-rs.enable = true;
    sebastianrasor.tailscale.enable = true;

    networking.timeServers = ["pool.ntp.org"];
    networking.domain = config.sebastianrasor.domain;
    networking.search = [config.sebastianrasor.domain];
    users.mutableUsers = false;
    users.users.root = {
      hashedPassword = "!";
      shell = pkgs.shadow;
    };
  };
}
