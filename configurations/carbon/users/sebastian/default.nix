{
  config,
  lib,
  ...
}: {
  users.users.sebastian = {
    isNormalUser = true;
    home = "/home/sebastian";
    description = "Sebastian Rasor";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = lib.mkIf config.sebastianrasor.sshd.enable [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG71B1X8QTaPtldyB7UvST8bzYBLSyXHkKJG2BbT0tkG"
    ];
  };

  home-manager.users.sebastian = lib.mkIf config.sebastianrasor.home-manager.enable (import ./home.nix);
}
