{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.git.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.git.enable {
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
    programs.fish.shellAbbrs = lib.mkIf config.sebastianrasor.fish.enable {
      ga = "git add";
      gc = "git commit";
      gca = "git commit --amend";
      gcm = "git commit -m";
      gd = "git diff";
      gds = "git diff --staged";
      gp = "git push";
      gr = "git restore";
      grh = "git reset HEAD";
      gs = "git status";
    };
  };
}
