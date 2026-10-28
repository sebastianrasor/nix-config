_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.bash;
in
{
  options.sebastianrasor.bash = {
    enable = lib.mkEnableOption "Bash";
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.bashInteractive
    ];

    environment.sessionVariables.HISTFILE = "${config.xdg.state.directory}/bash_history";

    files = {
      ".profile".source = config.environment.loadEnv;
      ".bash_profile".source = ./bash_profile;
      ".bashrc".source = ./bashrc;
    };
  };
}
