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

  sebastianrasor.ssh.addSshKeysToUsers = [ "sebastian" ];
}
