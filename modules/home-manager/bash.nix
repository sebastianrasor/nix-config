{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.bash;
in
{
  options.sebastianrasor.bash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bash.enable = true;
    home.sessionVariables.HISTFILE = "${config.xdg.stateHome}/bash_history";
  };
}
