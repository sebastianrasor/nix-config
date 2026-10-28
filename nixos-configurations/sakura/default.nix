{ nixos-hardware, ... }:
_: {
  networking.hostName = "sakura";

  sebastianrasor = {
    laptop.enable = true;

    disko = {
      enable = true;
      device = "/dev/disk/by-id/nvme-WD_BLACK_SN8100_2000GB_26011L801950";
      espSize = "8G";
      swapSize = "96G";
    };

    secrets.tpmAgeKey = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYZWQW3SRPQ9NRJLCH5M68CCZRWU3JND7JELART8QFKZWLSYH83DLWQPQDYZCRDKUJWZGZF0ZS7EU8TTKJ65RSMSXAZL8WUNHEC7XR67HFXSSQLSQYQC4GPP8S3DC2EQCFYZ46YDD4GZ7CJLJMS5C50FGYTLNF8EHVS7QWQQS9NDREZTWUCQGEFUA4CM8K8QNCTEC3APASGYDZCPKSU6F2VXETSCUYVFHTVEF8QK4KVLLS03U73ARDYDM6XC4P2887JFQKTD3TKVUF2A3AJM4CD058D7VWJ6XH7F40RDHQ2CGJTKZFHVPQA7UQQ3QQZ6WKNN0DM9R38ME4HJE25GM0G7LQU9P6X0EG7SLRJCCMR4X7LTLX5FZJK5P";
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
