# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ ... }:
{
  programs.vim = {
    enable = true;
    extraConfig = ''
              set viminfo+=n~/.local/state/viminfo
      	syntax on
      	set scrolloff=10
      	filetype plugin indent on
              let s:tabwidth=2
              let &l:tabstop = s:tabwidth
              let &l:shiftwidth = s:tabwidth
              let &l:softtabstop = s:tabwidth
    '';
  };

  xdg.desktopEntries = {
    vim = {
      name = "Vim";
      noDisplay = true;
    };

    gvim = {
      name = "GVim";
      noDisplay = true;
    };
  };
}
