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
      yubikey-personalization
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

    hardware.gpgSmartcards.enable = true;
  };
}
