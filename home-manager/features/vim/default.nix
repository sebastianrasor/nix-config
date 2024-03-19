{ pkgs, ... }: {
  #home.packages = with pkgs; [ vim ];
  programs.vim = {
    enable = true;
    defaultEditor = true;
    extraConfig =
      ''
        syntax on
        set tabstop=4
        autocmd FileType yaml setlocal ts=2 sts=2 expandtab
        autocmd FileType python setlocal ts=2 sts=2 expandtab
        autocmd FileType nix setlocal ts=2 sts=2 expandtab
        set scrolloff=3
        set conceallevel=0
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
