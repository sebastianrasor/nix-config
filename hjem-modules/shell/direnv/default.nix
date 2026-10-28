_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.direnv;
in
{
  options.sebastianrasor.direnv = {
    enable = lib.mkEnableOption "direnv";
  };

  config = lib.mkIf cfg.enable {
    packages = with pkgs; [
      direnv
      nix-direnv
    ];

    xdg.config.files = {
      "direnv/lib/nix-direnv.sh".source = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";
      "fish/conf.d/direnv.fish" = lib.mkIf config.sebastianrasor.fish.enable {
        source = ./direnv.fish;
      };
    };
  };
}
