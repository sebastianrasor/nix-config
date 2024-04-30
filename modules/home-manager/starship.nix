{ ... }: {
  programs.starship = {
    enable = true;
    enableTransience = true;
    settings = {
      cmd_duration.show_notifications = true;
      nix_shell.heuristic = true;
      sudo.disabled = false;
    };
  };
}
