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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sbctl
    ];

    boot.loader.systemd-boot.enable = lib.mkForce false;

    sebastianrasor.persistence.directories = [ "/var/lib/sbctl" ];

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
