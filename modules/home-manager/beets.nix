{ config, ... }: {
  programs.beets = {
    enable = true;
    settings = {
      directory = "${config.xdg.userDirs.music}";
    };
  };
}
