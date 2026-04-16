_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.git;
in
{
  options.sebastianrasor.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings = {
        init = {
          defaultBranch = "main";
        };
        user = {
          email = "https://www.sebastianrasor.com/contact";
          name = "Sebastian Rasor";
        };
      };
      signing = {
        format = "ssh";
        signByDefault = true;
        key = "~/.ssh/id_ed25519_sk.pub";
      };
    };
  };
}
