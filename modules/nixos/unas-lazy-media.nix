{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.unas-lazy-media.enable = lib.mkEnableOption "";

    sebastianrasor.unas-lazy-media.host = lib.mkOption {
      type = lib.types.str;
      default = config.sebastianrasor.unas.host;
    };

    sebastianrasor.unas-lazy-media.basePath = lib.mkOption {
      type = lib.types.str;
      default = config.sebastianrasor.unas.basePath;
    };
  };

  config = lib.mkIf config.sebastianrasor.unas-lazy-media.enable {
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
            what = "${config.sebastianrasor.unas-lazy-media.host}:${config.sebastianrasor.unas-lazy-media.basePath}/Movies";
            where = "/media/movies";
          }
        )

        (
          commonMountOptions
          // {
            what = "${config.sebastianrasor.unas-lazy-media.host}:${config.sebastianrasor.unas-lazy-media.basePath}/Shows";
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
        (commonAutoMountOptions // { where = "/media/shows"; })
      ];
  };
}
