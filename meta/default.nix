# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ ... }:
{
  imports = map (configModule: ./. + ("/" + configModule)) (
    builtins.filter (f: f != "default.nix") (builtins.attrNames (builtins.readDir ./.))
  );
}
