# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ pkgs, ... }:
{
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

  hardware.gpgSmartcards.enable = true;
}
