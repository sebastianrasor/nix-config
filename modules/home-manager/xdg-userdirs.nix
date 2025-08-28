{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.xdg-userdirs.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.xdg-userdirs.enable {
    xdg.userDirs = {
      enable = true;
      desktop = "${config.home.homeDirectory}/desktop";
      documents = "${config.home.homeDirectory}/documents";
      download = "${config.home.homeDirectory}/downloads";
      music = "${config.home.homeDirectory}/music";
      pictures = "${config.home.homeDirectory}/pictures";
      publicShare = "${config.home.homeDirectory}/public";
      templates = "${config.home.homeDirectory}/templates";
      videos = "${config.home.homeDirectory}/videos";
    };
    home.persistence."${config.sebastianrasor.persistence.storagePath}".directories = lib.mkIf config.sebastianrasor.persistence.enable (builtins.map (lib.strings.removePrefix config.home.homeDirectory) [
      config.xdg.userDirs.desktop
      config.xdg.userDirs.documents
      config.xdg.userDirs.download
      config.xdg.userDirs.music
      config.xdg.userDirs.pictures
      config.xdg.userDirs.publicShare
      config.xdg.userDirs.templates
      config.xdg.userDirs.videos
    ]);
  };
}
