{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.lanzaboote.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.lanzaboote.enable {
    environment.systemPackages = [
      pkgs.sbctl
    ];

    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
