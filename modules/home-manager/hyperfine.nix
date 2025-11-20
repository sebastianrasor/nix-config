{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.hyperfine.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.hyperfine.enable {
    home.packages = [ pkgs.hyperfine ];

    programs.fish.shellAbbrs = lib.mkIf config.sebastianrasor.fish.enable {
      hf = "hyperfine";
    };
  };
}
