{ ... }: {
  programs.git = {
    enable = true;
    userEmail = "https://www.sebastianrasor.com/contact";
    userName = "Sebastian Rasor";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
    signing = {
      signByDefault = true;
      key = "0878ED162F8B295F25AC197BF20DE4BA5B36D4E9";
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
}
