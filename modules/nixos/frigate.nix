{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.frigate.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.frigate.enable {
    users.users.frigate.extraGroups = lib.mkIf config.sebastianrasor.unas.enable ["unifi-drive-nfs"];

    security.acme.certs."frigate.rasor.us" = lib.mkIf config.sebastianrasor.acme.enable {
      dnsProvider = "cloudflare";
      environmentFile = "/nix/persist/acme-env";
    };

    services.nginx.virtualHosts."frigate.rasor.us" =
      lib.mkIf config.sebastianrasor.acme.enable
      {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;
      };

    services.frigate = {
      enable = true;
      hostname = "frigate.rasor.us";
      vaapiDriver = "iHD";
      settings = {
        database.path = lib.mkIf config.sebastianrasor.unas.enable "/media/frigate/frigate.db";
        record = {
          enabled = true;
          retain = {
            days = 14;
            mode = "all";
          };
          #alerts = {
          #  retain = {
          #    days = 30;
          #  };
          #};
          #detections = {
          #  retain = {
          #    days = 30;
          #  };
          #};
        };
        detectors.ov_0 = {
          type = "openvino";
          device = "GPU";
        };
        auth.reset_admin_password = true;
        ffmpeg.hwaccel_args = "preset-vaapi";
        model = {
          model_type = "yolonas";
          width = 320;
          height = 320;
          input_tensor = "nchw";
          input_pixel_format = "bgr";
          path = "/nix/persist/yolo_nas_s.onnx";
          labelmap_path = "/nix/persist/coco-80.txt";
        };
        cameras = {
          cam1 = {
            enabled = true;
            ffmpeg = {
              inputs = [
                {
                  path = "rtsp://admin:password1@10.0.108.219:554";
                  roles = ["record"];
                }
                {
                  path = "rtsp://admin:password1@10.0.108.219:554/cam/realmonitor?channel=1&subtype=1";
                  roles = ["detect"];
                }
              ];
            };
          };
          cam2 = {
            enabled = true;
            ffmpeg = {
              inputs = [
                {
                  path = "rtsp://admin:password1@10.0.108.189:554";
                  roles = ["record"];
                }
                {
                  path = "rtsp://admin:password1@10.0.108.189:554/cam/realmonitor?channel=1&subtype=1";
                  roles = ["detect"];
                }
              ];
            };
          };
          cam3 = {
            enabled = true;
            ffmpeg = {
              inputs = [
                {
                  path = "rtsp://admin:password1@10.0.108.237:554";
                  roles = ["record"];
                }
                {
                  path = "rtsp://admin:password1@10.0.108.237:554/cam/realmonitor?channel=1&subtype=1";
                  roles = ["detect"];
                }
              ];
            };
          };
          cam4 = {
            enabled = true;
            ffmpeg = {
              inputs = [
                {
                  path = "rtsp://admin:password1@10.0.108.225:554";
                  roles = ["record"];
                }
                {
                  path = "rtsp://admin:password1@10.0.108.225:554/cam/realmonitor?channel=1&subtype=1";
                  roles = ["detect"];
                }
              ];
            };
          };
          cam5 = {
            enabled = true;
            ffmpeg = {
              inputs = [
                {
                  path = "rtsp://admin:password1@10.0.108.214:554";
                  roles = ["record"];
                }
                {
                  path = "rtsp://admin:password1@10.0.108.214:554/cam/realmonitor?channel=1&subtype=1";
                  roles = ["detect"];
                }
              ];
            };
          };
        };
      };
    };

    fileSystems."/media/frigate" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Frigate";
      fsType = "nfs";
    };

    fileSystems."/var/lib/frigate/clips" = lib.mkIf config.sebastianrasor.unas.enable {
      depends = ["/media/frigate"];
      device = "/media/frigate/clips";
      fsType = "none";
      options = ["bind"];
    };

    fileSystems."/var/lib/frigate/exports" = lib.mkIf config.sebastianrasor.unas.enable {
      depends = ["/media/frigate"];
      device = "/media/frigate/exports";
      fsType = "none";
      options = ["bind"];
    };

    fileSystems."/var/lib/frigate/recordings" = lib.mkIf config.sebastianrasor.unas.enable {
      depends = ["/media/frigate"];
      device = "/media/frigate/recordings";
      fsType = "none";
      options = ["bind"];
    };
  };
}
