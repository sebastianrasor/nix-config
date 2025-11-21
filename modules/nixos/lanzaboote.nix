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

    sebastianrasor.persistence.directories = [ "/var/lib/sbctl" ];

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
