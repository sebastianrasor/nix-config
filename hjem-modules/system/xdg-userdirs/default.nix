_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.xdg-userdirs;
  dirs = {
    XDG_DESKTOP_DIR = "desktop";
    XDG_DOCUMENTS_DIR = "documents";
    XDG_DOWNLOAD_DIR = "downloads";
    XDG_MUSIC_DIR = "music";
    XDG_PICTURES_DIR = "pictures";
    XDG_PUBLICSHARE_DIR = "public";
    XDG_TEMPLATES_DIR = "templates";
    XDG_VIDEOS_DIR = "videos";
  };
in
{
  options.sebastianrasor.xdg-userdirs = {
    enable = lib.mkEnableOption "XDG user directories";
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.xdg-user-dirs
    ];

    xdg.config.files = {
      "user-dirs.conf".source = ./user-dirs.conf;
      "user-dirs.dirs".source = ./user-dirs.dirs;
    };

    environment.sessionVariables = lib.mapAttrs (_: dir: "${config.directory}/${dir}") dirs;

    sebastianrasor.persistence.directories = map (dir: "${config.directory}/${dir}") (
      builtins.attrValues dirs
    );
  };
}
