{ pkgs, ... }: {
  home.packages = with pkgs; [
    wl-clipboard
  ];
  programs.password-store.enable = true;
}
