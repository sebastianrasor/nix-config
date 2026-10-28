{ nixos-hardware, ... }:
_: {
  networking.hostName = "dahlia";

  hjem.users.sebastian.sebastianrasor.auto-rotate.enable = true;

  sebastianrasor = {
    core.enable = true;
    core.laptop = true;

    disko = {
      enable = true;
      device = "/dev/disk/by-id/nvme-WD_BLACK_SN770M_2TB_252272800093";
      espSize = "4G";
      swapSize = "64G";
    };

    sshd.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII85WkAO+BoPgHC8Vj7Y3ab3aOOLDx9e8jul4rBLAXiM";
  };

  imports = [
    nixos-hardware.nixosModules.framework-12-intel-core-series3
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";
}
