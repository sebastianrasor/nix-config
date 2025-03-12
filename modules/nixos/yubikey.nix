{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.yubikey.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.yubikey.enable {
    environment.systemPackages = with pkgs; [
      yubikey-manager
      yubikey-manager-qt
      yubikey-personalization
      yubikey-personalization-gui
      yubico-piv-tool
      yubioath-flutter
    ];

    services = {
      pcscd = {
        enable = true;
        plugins = [ pkgs.yubikey-personalization ];
      };
      udev.packages = [ pkgs.yubikey-personalization ];
    };

    security.pam.u2f = {
      enable = true;
      settings = {
        cue = true;
        pinverification = 1;
      };
    };

    hardware.gpgSmartcards.enable = true;
  };
}
