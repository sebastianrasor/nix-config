{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.makemkv;
in
{
  options.sebastianrasor.makemkv = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      makemkv
    ];

    boot.kernelModules = [ "sg" ];
  };
}
