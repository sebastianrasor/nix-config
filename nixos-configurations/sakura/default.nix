{ nixos-hardware, ... }:
_: {
  networking.hostName = "sakura";

  sebastianrasor = {
    core.enable = true;
    core.laptop = true;

    disko = {
      enable = true;
      device = "/dev/disk/by-id/nvme-WD_BLACK_SN8100_2000GB_26011L801950";
      espSize = "8G";
      swapSize = "96G";
    };

    sshd.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdHZOOgrwMkv66j61MiTU3oHacuTUW9+SL3r63P/3Ww";

    # https://forum.makemkv.com/forum/viewtopic.php?p=203406
    # makemkv.enable = true;
    steam.enable = true;

    unas = {
      enable = true;
      host = "unas-pro.internal";
      lazyMedia.enable = true;
    };
  };

  imports = [
    nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    ./hardware-configuration.nix
  ];

  system.stateVersion = "26.05";
}
