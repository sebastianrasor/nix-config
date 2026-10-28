{ disko, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.disko;
in
{
  options.sebastianrasor.disko = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    device = lib.mkOption {
      type = lib.types.str;
    };

    espSize = lib.mkOption {
      type = lib.types.str;
      default = "8G";
    };

    swapSize = lib.mkOption {
      type = lib.types.str;
    };
  };

  imports = [
    disko.nixosModules.disko
  ];

  config = lib.mkIf cfg.enable {
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
          inherit (cfg) device;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = cfg.espSize;
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
              size = cfg.swapSize;
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
          };
        };
      };
    };
  };
}
