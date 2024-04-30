{ ... }: {
  programs.vim = {
    enable = true;
    defaultEditor = true;
    extraConfig =
      ''
        syntax on
        set tabstop=4
        set shiftwidth=4
        autocmd FileType yaml setlocal ts=2 sts=2 expandtab
        autocmd FileType python setlocal ts=2 sts=2 expandtab
        autocmd FileType nix setlocal ts=2 sts=2 expandtab
        set scrolloff=3
        set conceallevel=0
        set autoindent
        set smartindent
        set cindent
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
