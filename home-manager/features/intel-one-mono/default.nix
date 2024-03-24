{ pkgs, ... }: {
  home.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "IntelOneMono"
      ];
    })
  ];
  fonts.fontconfig.enable = true;
}
