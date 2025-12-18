{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.starship;
in
{
  options.sebastianrasor.starship = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableTransience = true;
      settings = {
        nix_shell.heuristic = true;
        shlvl.disabled = false;
      };
    };
  };
}
