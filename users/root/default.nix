# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ pkgs, ... }:
{
  users.users.root = {
    shell = pkgs.fish;
  };

  home-manager.users.root = import ./home.nix;
}
