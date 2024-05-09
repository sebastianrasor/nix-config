{ ... }: {
  programs.vim = {
    enable = true;
    defaultEditor = true;
    extraConfig =
      ''
        syntax on
        set tabstop=4
        set shiftwidth=4
        set list
        autocmd FileType yaml setlocal ts=2 sw=2 expandtab
        autocmd FileType html setlocal ts=2 sw=2 expandtab
        autocmd FileType css setlocal ts=2 sw=2 expandtab
        autocmd FileType python setlocal ts=2 sw=2 expandtab
        autocmd FileType javascript setlocal ts=2 sw=2 expandtab
        autocmd FileType typescript setlocal ts=2 sw=2 expandtab
        autocmd FileType nix setlocal ts=2 sw=2 expandtab
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
