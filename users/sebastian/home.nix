# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ pkgs, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    packages = with pkgs; [
      bandwhich
      bottom
      discord
      google-chrome
      macchina
      mpv
      onefetch
      thunderbird
      tldr
      yubioath-flutter
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      COSMIC_DISABLE_DIRECT_SCANOUT = "true";
    };

    stateVersion = "23.11";
  };

  programs.home-manager.enable = true;

  imports = map (configModule: ./. + ("/" + configModule)) (
    builtins.filter (f: f != "default.nix" && f != "home.nix") (
      builtins.attrNames (builtins.readDir ./.)
    )
  );
}
