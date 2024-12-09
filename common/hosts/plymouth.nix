# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ pkgs, ... }:
{
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;
    loader.timeout = 0;
    plymouth = {
      enable = true;
      theme = "lone";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = [ "lone" ];
        })
      ];
    };
  };
}
