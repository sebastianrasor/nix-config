# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ ... }:
{
  services.xserver = {
    xkb.layout = "dvorak";
  };

  console = {
    earlySetup = true;
    keyMap = "dvorak";
  };
}
