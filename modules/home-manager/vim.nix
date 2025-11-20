{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.vim.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.vim.enable {
    programs.vim = {
      enable = true;
      extraConfig = ''
        set viminfo+=n~/.local/state/viminfo
        syntax on
        set t_Co=16
        set scrolloff=10
        filetype plugin indent on
        let s:tabwidth=2
        let &l:tabstop = s:tabwidth
        let &l:shiftwidth = s:tabwidth
        let &l:softtabstop = s:tabwidth
      '';
    };
  };
}
