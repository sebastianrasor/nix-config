pkgs:
let
  inherit (pkgs) lib;
  packages = import ./packages pkgs;
  packageChecks = lib.concatMapAttrs (
    pkgName: pkg:
    lib.mapAttrs' (checkName: check: lib.nameValuePair "${pkgName}-${checkName}" check) (
      pkg.passthru.checks or { }
    )
  ) packages;
in
packages
// packageChecks
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
