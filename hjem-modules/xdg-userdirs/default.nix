_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.xdg-userdirs;
in
{
  options.sebastianrasor.xdg-userdirs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.xdg-user-dirs
    ];

    xdg.config.files = {
      "user-dirs.conf".source = ./user-dirs.conf;
      "user-dirs.dirs".source = ./user-dirs.dirs;
    };

    environment.sessionVariables = {
      XDG_DESKTOP_DIR = "${config.directory}/desktop";
      XDG_DOCUMENTS_DIR = "${config.directory}/documents";
      XDG_DOWNLOAD_DIR = "${config.directory}/downloads";
      XDG_MUSIC_DIR = "${config.directory}/music";
      XDG_PICTURES_DIR = "${config.directory}/pictures";
      XDG_PUBLICSHARE_DIR = "${config.directory}/public";
      XDG_TEMPLATES_DIR = "${config.directory}/templates";
      XDG_VIDEOS_DIR = "${config.directory}/videos";
    };

    sebastianrasor.persistence.directories = [
      "${config.directory}/desktop"
      "${config.directory}/documents"
      "${config.directory}/downloads"
      "${config.directory}/music"
      "${config.directory}/pictures"
      "${config.directory}/public"
      "${config.directory}/templates"
      "${config.directory}/videos"
    ];
  };
}
