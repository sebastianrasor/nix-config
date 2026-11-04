pkgs:
(import ./packages pkgs)
// {
  formatting =
    pkgs.runCommand "check-formatting"
      {
        nativeBuildInputs = with pkgs; [
          fd
          nixfmt
        ];
      }
      ''
        fd -e nix -E hardware-configuration.nix -X nixfmt --check ${./.}
        touch "$out"
      '';
  statix =
    pkgs.runCommand "check-statix"
      {
        nativeBuildInputs = [ pkgs.statix ];
      }
      ''
        statix check -i '**/hardware-configuration.nix' ${./.}
        touch "$out"
      '';
}
