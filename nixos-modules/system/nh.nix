{ constants, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.nh;
in
{
  options.sebastianrasor.nh = {
    enable = lib.mkEnableOption "nh";
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      flake = "git+https://github.com/sebastianrasor/nix-config";
      clean = {
        enable = true;
        extraArgs = "--keep 10 --keep-since 7d";
        dates = "daily";
      };
    };
  };
}
