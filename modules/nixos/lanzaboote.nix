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

    environment.persistence."${config.sebastianrasor.persistence.storagePath}".directories =
      lib.mkIf config.sebastianrasor.persistence.enable
        [ "/var/lib/sbctl" ];

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
