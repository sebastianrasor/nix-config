{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.monaspace;
in
{
  options.sebastianrasor.monaspace = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nerd-fonts.monaspace
    ];

    fonts.fontconfig.enable = true;
  };
}
