# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ pkgs, ... }:
{
  users.users.sebastian = {
    description = "Sebastian Rasor";
    extraGroups = [
      "networkmanager"
      "video"
      "wheel"
    ];
    isNormalUser = true;
    shell = pkgs.fish;
  };

  home-manager.users.sebastian = import ./home.nix;
}
