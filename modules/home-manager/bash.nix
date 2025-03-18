{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.bash.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.bash.enable {
    home.sessionVariables = {
      HISTFILE = "$HOME/.local/state/bash_history";
    };
    programs.bash.enable = true;
  };
}
