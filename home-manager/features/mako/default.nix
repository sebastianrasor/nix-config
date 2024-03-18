{ pkgs, ... }: {
  home.packages = with pkgs; [
    libnotify
    mako
  ];
  services.mako = {
    enable = true;
  };
}
