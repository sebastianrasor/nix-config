_:
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
    enable = lib.mkEnableOption "MakeMKV";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      makemkv
    ];

    boot.kernelModules = [ "sg" ];
  };
}
