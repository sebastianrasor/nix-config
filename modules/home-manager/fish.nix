{
  config,
  lib,
  pkgs,
  ...
}: {
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
      functions = {
        fish_greeting = "test -e /etc/motd; and command cat /etc/motd";
        fish_user_key_bindings = "fish_default_key_bindings -M insert; fish_vi_key_bindings --no-erase insert";
      };
      interactiveShellInit = "fish_config theme choose 'fish default'; set -g fish_color_command blue; set -g fish_color_keyword blue";
    };
    programs.bash.initExtra = lib.mkIf config.sebastianrasor.fish.bashInit ''
      if [[ $(${lib.getExe' pkgs.procps "ps"} --no-header --pid=$PPID --format=comm) != "fish" && -z ''\${BASH_EXECUTION_STRING} && ''\${SHLVL} == 1 ]]; then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''\'''\'
        exec ${lib.getExe' config.programs.fish.package "fish"} $LOGIN_OPTION
      fi
    '';
  };
}
