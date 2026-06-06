{
  config,
  lib,
  ...
}:
{
  users.users.sebastian = {
    isNormalUser = true;
    home = "/home/sebastian";
    description = "Sebastian Rasor";
    extraGroups = [
      "tss"
      "wheel"
    ];
  };

  home-manager.users.sebastian = lib.mkIf config.sebastianrasor.home-manager.enable (
    import ./home.nix
  );

  sebastianrasor.ssh.addSshKeysToUsers = [ "sebastian" ];
}
