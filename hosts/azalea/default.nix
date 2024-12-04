# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ nixos-hardware, ... }:
{
  imports =
    map (configModule: ./. + ("/" + configModule)) (
      builtins.filter (f: f != "default.nix") (builtins.attrNames (builtins.readDir ./.))
    )
    ++ [
      nixos-hardware.nixosModules.framework-13-7040-amd
    ];

  networking.hostName = "azalea";

  system.stateVersion = "23.11";
}
