# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  programs.neovim = {
    enable = true;
    extraLuaConfig = lib.fileContents ./init.lua;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    plugins = with pkgs.vimPlugins; [
      hardtime-nvim
      nui-nvim
      plenary-nvim
      solarized-nvim
    ];
  };
  programs.fish.shellAbbrs = {
    vim = "nvim";
  };
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    noDisplay = true;
  };
}
