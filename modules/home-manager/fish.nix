{ inputs, lib, pkgs, ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit =
      ''
        set -g fish_key_bindings fish_vi_key_bindings
      '';
    functions = {
      fish_greeting = "${lib.getExe pkgs.fortune} -s | ${lib.getExe' pkgs.cowsay "cowsay"} -f (ls -1 ${pkgs.cowsay}/share/cowsay/cows/*.cow | shuf -n 1) | ${lib.getExe pkgs.lolcat} -t";
    };
  };
  xdg.desktopEntries.fish = {
    name = "Fish";
    noDisplay = true;
  };
}
