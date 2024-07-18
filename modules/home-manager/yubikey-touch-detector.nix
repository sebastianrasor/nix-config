{ config, lib, pkgs, ... }: {
  home = {
    file.yubikey-touch-detector-service = {
      source = "${pkgs.yubikey-touch-detector}/lib/systemd/user/yubikey-touch-detector.service";
      target = ".config/systemd/user/yubikey-touch-detector.service";
    };
    file.yubikey-touch-detector-socket = {
      source = "${pkgs.yubikey-touch-detector}/lib/systemd/user/yubikey-touch-detector.socket";
      target = ".config/systemd/user/yubikey-touch-detector.socket";
    };
    file.yubikey-touch-detector-config = {
      text = ''
        GNUPGHOME=${config.programs.gpg.homedir}
        YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=false
      '';
      target = ".config/yubikey-touch-detector/service.conf";
    };
    packages = with pkgs; [ yubikey-touch-detector ];
  };
}
