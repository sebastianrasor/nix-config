{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.jnv.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.jnv.enable {
    home.packages = [pkgs.jnv];
  };
}
