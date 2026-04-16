_:
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
          backend = "ssh";
          key = "~/.ssh/id_ed25519_sk.pub";
        };
        git.sign-on-push = true;
      };
    };
  };
}
