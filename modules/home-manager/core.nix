{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.core.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.core.enable {
    sebastianrasor.bandwhich.enable = true;
    sebastianrasor.bash.enable = true;
    sebastianrasor.bat.enable = true;
    sebastianrasor.direnv.enable = true;
    sebastianrasor.dust.enable = true;
    sebastianrasor.eza.enable = true;
    sebastianrasor.fish.enable = true;
    sebastianrasor.gitoxide.enable = true;
    sebastianrasor.gping.enable = true;
    sebastianrasor.hyperfine.enable = true;
    sebastianrasor.jnv.enable = true;
    sebastianrasor.jq.enable = true;
    sebastianrasor.miniserve.enable = true;
    sebastianrasor.monolith.enable = true;
    sebastianrasor.navi.enable = true;
    sebastianrasor.ripgrep.enable = true;
    sebastianrasor.ssh.enable = true;
    sebastianrasor.starship.enable = true;
    sebastianrasor.tokei.enable = true;
    sebastianrasor.vim.enable = true;
    sebastianrasor.xdg-userdirs.enable = true;
    sebastianrasor.yazi.enable = true;
    sebastianrasor.zoxide.enable = true;

    programs.home-manager.enable = true;
  };
}
