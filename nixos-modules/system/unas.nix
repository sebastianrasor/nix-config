_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.unas;
in
{
  options.sebastianrasor.unas = {
    enable = lib.mkEnableOption "UNAS";

    host = lib.mkOption {
      type = lib.types.str;
      default = "unas-pro.internal";
    };

    basePath = lib.mkOption {
      type = lib.types.str;
      default = "/var/nfs/shared";
    };

    mounts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };

    lazyMedia.enable = lib.mkEnableOption "UNAS lazy media mounts";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      users.groups.unifi-drive.gid = 988;
      users.users.unifi-drive-nfs = {
        group = "unifi-drive";
        isSystemUser = true;
        uid = 977;
      };

      fileSystems = lib.mapAttrs' (
        shareName: mountPath:
        lib.nameValuePair mountPath {
          device = "${cfg.host}:${cfg.basePath}/${shareName}";
          fsType = "nfs";
        }
      ) cfg.mounts;
    })
    (lib.mkIf cfg.lazyMedia.enable {
      environment.systemPackages = with pkgs; [
        nfs-utils
      ];

      boot.supportedFilesystems = [ "nfs" ];
      services.rpcbind.enable = true; # needed for NFS
      systemd.mounts =
        let
          commonMountOptions = {
            type = "nfs";
            mountConfig = {
              Options = "noatime";
            };
          };
        in
        [
          (
            commonMountOptions
            // {
              what = "${cfg.host}:${cfg.basePath}/Movies";
              where = "/media/movies";
            }
          )
          (
            commonMountOptions
            // {
              what = "${cfg.host}:${cfg.basePath}/Music";
              where = "/media/music";
            }
          )
          (
            commonMountOptions
            // {
              what = "${cfg.host}:${cfg.basePath}/Shows";
              where = "/media/shows";
            }
          )
        ];

      systemd.automounts =
        let
          commonAutoMountOptions = {
            wantedBy = [ "multi-user.target" ];
            automountConfig = {
              TimeoutIdleSec = "600";
            };
          };
        in
        [
          (commonAutoMountOptions // { where = "/media/movies"; })
          (commonAutoMountOptions // { where = "/media/music"; })
          (commonAutoMountOptions // { where = "/media/shows"; })
        ];
    })
  ];
}
