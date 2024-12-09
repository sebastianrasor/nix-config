# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ lib, nixos-hardware, ... }:
{
  imports =
    map (configModule: ./. + ("/" + configModule)) (
      builtins.filter (f: f != "default.nix") (builtins.attrNames (builtins.readDir ./.))
    )
    ++ [
      nixos-hardware.nixosModules.framework-13-7040-amd
    ];

  networking.hostName = "azalea";

  hardware.bluetooth.powerOnBoot = lib.mkForce false;

  system.stateVersion = "23.11";
}
