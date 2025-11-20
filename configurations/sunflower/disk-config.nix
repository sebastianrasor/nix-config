{ ... }:
{
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
        device = "/dev/disk/by-id/nvme-WD_BLACK_SN770M_2TB_252272800093";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "4G";
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
            size = "64G";
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
