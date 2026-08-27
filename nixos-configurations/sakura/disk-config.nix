{ disko, ... }:
{
  imports = [
    disko.nixosModules.disko
  ];

  disko.devices = {
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "defaults"
        "mode=755"
      ];
    };
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-WD_BLACK_SN8100_2000GB_26011L801950";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "8G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            cryptlvm = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptlvm";
                settings.allowDiscards = true;
                passwordFile = "/tmp/secret.key";
                content = {
                  type = "lvm_pv";
                  vg = "cryptvg";
                };
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      cryptvg = {
        type = "lvm_vg";
        lvs = {
          nix = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = [ "defaults" ];
            };
          };
          swap = {
            size = "96G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
        };
      };
    };
  };
}
