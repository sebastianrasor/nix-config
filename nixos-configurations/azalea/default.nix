{ nixos-hardware, ... }:
_: {
  networking.hostName = "azalea";

  sebastianrasor = {
    core.enable = true;
    core.laptop = true;

    sshd.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO5pVGXbupdNG/9acDwOd6loG8CBBaNsreyoYCY4at9J";

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
    nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
  ];

  system.stateVersion = "23.11";
}
