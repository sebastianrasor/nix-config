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
        signByDefault = true;
        key = "9CBD407F060D20898ED1F280E346A2A083D90F7D";
      };
      includes = [
        {
          condition = "hasconfig:remote.*.url:git@github.com:*/**";
          contents = {
            user.email = "92653912+sebastianrasor@users.noreply.github.com";
          };
        }
      ];
    };
  };
}
