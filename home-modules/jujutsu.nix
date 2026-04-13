{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.jujutsu;
in
{
  options.sebastianrasor.jujutsu = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          email = "https://www.sebastianrasor.com/contact";
          name = "Sebastian Rasor";
        };
        signing = {
          behavior = "drop";
          backend = "gpg";
          key = "9CBD407F060D20898ED1F280E346A2A083D90F7D";
        };
        git.sign-on-push = true;
      };
    };
  };
}
