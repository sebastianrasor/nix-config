_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.core;
in
{
  options.sebastianrasor.core = {
    enable = lib.mkEnableOption "core user configuration";

    graphical = lib.mkEnableOption "graphical user configuration";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      packages = with pkgs; [
        bat
        bottom
        dust
        dysk
        eza
        jq
        ripgrep
        zoxide
      ];

      sebastianrasor = {
        bash.enable = lib.mkDefault true;
        direnv.enable = lib.mkDefault true;
        fish.enable = lib.mkDefault true;
        git.enable = lib.mkDefault true;
        helix.enable = lib.mkDefault true;
        jujutsu.enable = lib.mkDefault true;
        persistence.directories = [
          config.xdg.data.directory
          config.xdg.state.directory
        ];
        ssh.enable = lib.mkDefault true;
        starship.enable = lib.mkDefault true;
        xdg-userdirs.enable = lib.mkDefault true;
      };
    })
    (lib.mkIf cfg.graphical {
      packages = with pkgs; [
        discord
        google-chrome
        thunderbird
      ];

      sebastianrasor = {
        atkinson-hyperlegible.enable = lib.mkDefault true;
        cosmic.enable = lib.mkDefault true;
        emoji.enable = lib.mkDefault true;
        gpg.enable = lib.mkDefault true;
        pass.enable = lib.mkDefault true;
        persistence.directories = [
          "${config.xdg.config.directory}/discord"
          "${config.xdg.config.directory}/google-chrome"
          "${config.directory}/.thunderbird"
        ];
        posy-cursors.enable = lib.mkDefault true;
        yubikey-touch-detector.enable = lib.mkDefault true;
      };

      systemd.services.tailscale-systray = {
        description = "Official Tailscale systray application for Linux";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig.ExecStart = "${lib.getExe pkgs.tailscale} systray";
      };
    })
  ];
}
