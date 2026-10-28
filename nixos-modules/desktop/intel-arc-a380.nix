_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.intel-arc-a380;
in
{
  options.sebastianrasor.intel-arc-a380 = {
    enable = lib.mkEnableOption "Intel Arc A380";
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [ "i915.enable_guc=3" ];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };

    hardware = {
      enableAllFirmware = true;
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver # VA-API (iHD) userspace
          vpl-gpu-rt # oneVPL (QSV) runtime

          intel-compute-runtime # OpenCL (NEO) + Level Zero for Arc/Xe
        ];
      };
    };
  };
}
