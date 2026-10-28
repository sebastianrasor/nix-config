_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.vim;
in
{
  options.sebastianrasor.vim = {
    enable = lib.mkEnableOption "Vim";
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.vim
    ];

    environment.sessionVariables = {
      EDITOR = lib.mkDefault "vim";
      VISUAL = lib.mkDefault "vim";
    };

    xdg.config.files."vim/vimrc".source = ./vimrc;
  };
}
