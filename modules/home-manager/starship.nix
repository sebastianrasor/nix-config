{ ... }: {
  programs.starship = {
    enable = true;
    settings = {
      cmd_duration.show_notifications = true;
      nix_shell.heuristic = true;
      sudo.disabled = false;
    };
  };
}
