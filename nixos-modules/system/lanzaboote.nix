{
  lanzaboote,
  pkgsFor ? { },
  ...
}:
let
  mkLzbt =
    pkgs:
    (import lanzaboote {
      inherit pkgs;
      crane = pkgs.craneLib;
      inherit (lanzaboote.inputs) rust-overlay;
    }).packages.lzbt;
  lzbtBySystem = builtins.mapAttrs (_: mkLzbt) pkgsFor;
in
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.lanzaboote;
in
{
  options.sebastianrasor.lanzaboote = {
    enable = lib.mkEnableOption "lanzaboote";
  };

  imports = [
    "${lanzaboote}/nix/modules/lanzaboote.nix"
  ];

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sbctl
    ];

    boot.loader.systemd-boot.enable = lib.mkForce false;

    sebastianrasor.persistence.directories = [ "/var/lib/sbctl" ];

    boot.lanzaboote = {
      enable = true;
      package = lzbtBySystem.${pkgs.stdenv.hostPlatform.system} or (mkLzbt pkgs);
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
