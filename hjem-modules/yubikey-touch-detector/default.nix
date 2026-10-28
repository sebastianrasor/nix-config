_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.yubikey-touch-detector;
in
{
  options.sebastianrasor.yubikey-touch-detector = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = with pkgs; [
      libnotify
      yubikey-touch-detector
    ];

    xdg.config.files."yubikey-touch-detector/service.conf".source = ./service.conf;

    systemd.services.yubikey-touch-detector = {
      description = "Detects when your YubiKey is waiting for a touch";
      requires = [ "yubikey-touch-detector.socket" ];
      wantedBy = [ "default.target" ];
      environment.GNUPGHOME = config.sebastianrasor.gpg.homedir;
      serviceConfig = {
        ExecStart = lib.getExe pkgs.yubikey-touch-detector;
        EnvironmentFile = "-%E/yubikey-touch-detector/service.conf";
      };
    };

    systemd.sockets.yubikey-touch-detector = {
      description = "Unix socket activation for YubiKey touch detector service";
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = "%t/yubikey-touch-detector.socket";
        RemoveOnStop = true;
      };
    };
  };
}
