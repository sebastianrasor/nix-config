{ nixos-hardware, ... }:
_: {
  networking.hostName = "azalea";

  sebastianrasor = {
    laptop.enable = true;

    secrets.tpmAgeKey = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYRVHE8LC9GY4TT2SN3X9L22W0H7F0EPEQCZNR6JLZNUVJD9D769RXQPQ022JU0EE3WP5UWKK3F2P6CX0DE0M0SE5RTNDPW7CRJ52XR5JQDYSQLSQYQ6WCCYP4WUVVXM6RRKPF4ZCDJYQFP9NYG7C2PJXM4KU950QPF5VVQQS63HT5AKHD5KSRXEG2N3D3YZYFGJMJTGWSG3RNHQ7KFNHT9EPXZHQTC8MV3HP7K2Q7Y4KM70F6FU8QE2PP86KSPVXKP9WZHNHRXETMFWNLR7JRT4ATKY6L63UFZ5X7E3XUNKV70DUSE290K95QQ3QQZ7RLP4L9T0PXEWE3TFP8MLZF4U4CSDR9FN6HD74QWQSY08JXN80JYAVVW74";
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

  hardware.framework.laptop13.audioEnhancement.enable = true;

  imports = [
    nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
  ];

  system.stateVersion = "23.11";
}
