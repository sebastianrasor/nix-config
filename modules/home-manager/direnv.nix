{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.direnv.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.direnv.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    home.persistence."${config.sebastianrasor.persistence.storagePath}".directories =
      lib.mkIf config.sebastianrasor.persistence.enable
        (
          builtins.map (lib.strings.removePrefix config.home.homeDirectory) [
            "${config.xdg.dataHome}/direnv"
          ]
        );
  };
}
