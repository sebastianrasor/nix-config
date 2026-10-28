_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.yubikey;
in
{
  options.sebastianrasor.yubikey = {
    enable = lib.mkEnableOption "YubiKey";
  };

  config = lib.mkIf cfg.enable {
    hardware.gpgSmartcards.enable = true;

    services = {
      pcscd = {
        enable = true;
        plugins = with pkgs; [
          yubikey-personalization
        ];
      };
      udev.packages = with pkgs; [
        yubikey-personalization
      ];
    };

    environment.systemPackages = with pkgs; [
      yubikey-manager
      yubikey-personalization
      yubico-piv-tool
      yubioath-flutter
    ];
  };
}
