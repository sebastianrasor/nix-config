{ pkgs, ... }: {
  home.packages = with pkgs; [
    mpc-cli
  ];
}
