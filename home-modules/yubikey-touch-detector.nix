{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.sebastianrasor.yubikey-touch-detector;
  yubikey-touch-detector =
    inputs.yubikey-touch-detector.packages.${pkgs.stdenv.hostPlatform.system}.yubikey-touch-detector;
in
{
  options.sebastianrasor.yubikey-touch-detector = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      file.yubikey-touch-detector-config = {
        text = ''
          GNUPGHOME=${config.programs.gpg.homedir}
          YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=true
        '';
        target = ".config/yubikey-touch-detector/service.conf";
      };
      packages = [
        pkgs.libnotify
        yubikey-touch-detector
      ];
    };
    systemd.user.services = {
      yubikey-touch-detector = {
        Unit = {
          Description = "Detects when your YubiKey is waiting for a touch";
          Requires = "yubikey-touch-detector.socket";
        };
        Service = {
          ExecStart = lib.getExe' yubikey-touch-detector "yubikey-touch-detector";
          EnvironmentFile = "-%E/yubikey-touch-detector/service.conf";
        };
        Install = {
          Also = "yubikey-touch-detector.socket";
          WantedBy = [ "default.target" ];
        };
      };
    };
    systemd.user.sockets = {
      yubikey-touch-detector = {
        Unit = {
          Description = "Unix socket activation for YubiKey touch detector service";
        };
        Socket = {
          ListenStream = "%t/yubikey-touch-detector.socket";
          RemoveOnStop = "yes";
        };
        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    };
  };
}
