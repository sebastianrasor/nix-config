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

    graphical = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      sebastianrasor = {
        bandwhich.enable = true;
        bash.enable = true;
        bat.enable = true;
        bottom.enable = true;
        direnv.enable = true;
        dust.enable = true;
        dysk.enable = true;
        eza.enable = true;
        fish.enable = true;
        git.enable = true;
        gping.enable = true;
        hyperfine.enable = true;
        jq.enable = true;
        monolith.enable = true;
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
        zoxide.enable = true;
      };

      programs.home-manager.enable = true;
    })
    (lib.mkIf cfg.graphical {
      sebastianrasor = {
        atkinson-hyperlegible.enable = true;
        browserpass.enable = true;
        cosmic.enable = true;
        discord.enable = true;
        google-chrome.enable = true;
        gpg.enable = true;
        nvf.enable = true;
        pass.enable = true;
        posy-cursors.enable = true;
        tailscale-systray.enable = true;
        thunderbird.enable = true;
        yubikey-touch-detector.enable = true;
      };
    })
  ];
}
