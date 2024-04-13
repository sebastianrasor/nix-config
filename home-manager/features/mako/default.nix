{ pkgs, ... }: {
  services.mako = {
    enable = true;
    backgroundColor = "#000000BF";
    borderColor = "#0000007F";
    borderRadius = 10;
    defaultTimeout = 5000;
    font = "Atkinson Hyperlegible";
    margin = "10";
    padding = "10";
    extraConfig = ''
      outer-margin=5
    '';
  };
}
