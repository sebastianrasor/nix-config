{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.nut;
in
{
  options.sebastianrasor.nut = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    power.ups = {
      enable = true;
      openFirewall = true;
      mode = "netserver";
      ups.ups1 = {
        driver = "usbhid-ups";
        port = "auto";
      };
      upsd.listen = [
        {
          address = "0.0.0.0";
        }
      ];
      users = {
        upsmon = {
          upsmon = "primary";
          passwordFile = builtins.toFile "upsmon.password" "nut-password";
        };
        homeassistant = {
          upsmon = "secondary";
          passwordFile = builtins.toFile "homeassistant.password" "nut-password";
        };
      };
      upsmon.monitor.ups1.user = "upsmon";
    };
  };
}
