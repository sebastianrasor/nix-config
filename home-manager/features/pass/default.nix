{ pkgs, ... }: {
  home.packages = with pkgs; [
    pass
    wl-clipboard
  ];
  programs.password-store.enable = true;
}
