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
  };

  sebastianrasor.ssh.addSshKeysToUsers = [ "sebastian" ];
}
