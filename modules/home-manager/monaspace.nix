{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.monaspace.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.monaspace.enable {
    fonts.fontconfig.enable = true;
    home.packages = [
      pkgs.nerd-fonts.monaspace
    ];
  };
}
