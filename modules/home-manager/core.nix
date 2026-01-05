{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.core;
in
{
  options.sebastianrasor.core = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    sebastianrasor = {
      bandwhich.enable = true;
      bash.enable = true;
      bat.enable = true;
      bottom.enable = true;
      direnv.enable = true;
      dust.enable = true;
      eza.enable = true;
      fish.enable = true;
      git.enable = true;
      gitoxide.enable = true;
      gping.enable = true;
      hyperfine.enable = true;
      jnv.enable = true;
      jq.enable = true;
      miniserve.enable = true;
      monolith.enable = true;
      navi.enable = true;
      persistence.directories = [
        config.xdg.dataHome
        config.xdg.stateHome
      ];
      ripgrep.enable = true;
      ssh.enable = true;
      starship.enable = true;
      tokei.enable = true;
      vim.enable = true;
      xdg-userdirs.enable = true;
      yazi.enable = true;
      zoxide.enable = true;
    };

    programs.home-manager.enable = true;
  };
}
