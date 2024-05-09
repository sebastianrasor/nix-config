{ ... }: {
  programs.starship = {
    enable = true;
    enableTransience = true;
    settings = {
      nix_shell.heuristic = true;
      sudo.disabled = false;
    };
  };
}
