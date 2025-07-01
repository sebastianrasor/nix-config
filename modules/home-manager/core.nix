{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.core.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.core.enable {
    sebastianrasor.bash.enable = true;
    sebastianrasor.bat.enable = true;
    sebastianrasor.direnv.enable = true;
    sebastianrasor.dust.enable = true;
    sebastianrasor.eza.enable = true;
    sebastianrasor.fish.enable = true;
    sebastianrasor.ripgrep.enable = true;
    sebastianrasor.starship.enable = true;
    sebastianrasor.vim.enable = true;
    sebastianrasor.xdg-userdirs.enable = true;
    sebastianrasor.yazi.enable = true;
    sebastianrasor.zoxide.enable = true;
  };
}
