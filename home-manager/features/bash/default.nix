{ ... }: {
  programs.bash = {
    enable = true;
    initExtra =
      ''
        WHICH_FISH="$(which fish)"
        if [[ "$-" =~ i && -x "''${WHICH_FISH}" && ! "''${SHELL}" -ef "''${WHICH_FISH}" ]]; then
          exec env SHELL="''${WHICH_FISH}" "''${WHICH_FISH}" -i
        fi
      ''; 
  };      
}
