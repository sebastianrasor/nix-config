_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.auto-rotate;
in
{
  options.sebastianrasor.auto-rotate = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.auto-rotate = {
      description = "Automatically rotates the screen";
      wantedBy = [ "default.target" ];
      serviceConfig.ExecStart =
        let
          autoRotateScript = pkgs.writeShellApplication {
            name = "auto-rotate";
            runtimeInputs = with pkgs; [
              iio-sensor-proxy
              wlr-randr
            ];
            text = builtins.readFile ./auto-rotate.sh;
          };
        in
        lib.getExe autoRotateScript;
    };
  };
}
