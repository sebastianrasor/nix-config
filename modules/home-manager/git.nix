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
}
