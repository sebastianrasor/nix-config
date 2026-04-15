{
  config,
  constants,
  lib,
  ...
}:
{
  users.users.sebastian = {
    isNormalUser = true;
    home = "/home/sebastian";
    description = "Sebastian Rasor";
    extraGroups = [
      "dialout"
      "lp"
      "networkmanager"
      "scanner"
      "tss"
      "wheel"
    ];
    openssh.authorizedKeys.keys = constants.sshPublicKeys;
  };

  home-manager.users.sebastian = lib.mkIf config.sebastianrasor.home-manager.enable (
    import ./home.nix
  );
}
