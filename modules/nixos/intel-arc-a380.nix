{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.intel-arc-a380.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.intel-arc-a380.enable {
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-compute-runtime
        intel-media-driver
        intel-ocl
        vpl-gpu-rt
      ];
    };
  };
}
