{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.discord.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.discord.enable {
    home.packages = [pkgs.discord];
  };
}
