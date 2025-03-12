{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.fish.enable = lib.mkEnableOption "";

    sebastianrasor.fish.bashInit = lib.mkOption {
      type = lib.types.bool;
      default = config.sebastianrasor.bash.enable;
    };
  };

  config = lib.mkIf config.sebastianrasor.fish.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_key_bindings fish_vi_key_bindings
      '';
      functions = {
        fish_greeting = "test -e /etc/motd; and command cat /etc/motd";
      };
    };
    programs.bash.initExtra = lib.mkIf config.sebastianrasor.fish.bashInit ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${config.programs.fish.package}/bin/fish $LOGIN_OPTION
      fi
    '';
    xdg.desktopEntries.fish = {
      name = "Fish";
      noDisplay = true;
    };
  };
}
