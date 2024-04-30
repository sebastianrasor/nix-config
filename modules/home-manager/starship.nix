{ ... }: {
  programs.starship = {
    enable = true;
    enableTransience = true;
    settings = {
      nix_shell = {
        heuristic = true;
      };
      cmd_duration = {
        show_notifications = true;
      };
    };
  };
}
