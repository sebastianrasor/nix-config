# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ ... }:
{
  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "23.11";
  };

  programs.home-manager.enable = true;

  imports = map (configModule: ./. + ("/" + configModule)) (
    builtins.filter (f: f != "default.nix" && f != "home.nix") (
      builtins.attrNames (builtins.readDir ./.)
    )
  );
}
