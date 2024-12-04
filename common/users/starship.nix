# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ ... }:
{
  programs.starship = {
    enable = true;
    enableTransience = true;
    settings.nix_shell.heuristic = true;
  };
}
