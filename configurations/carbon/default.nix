# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{...}: {
  networking.hostName = "carbon";

  sebastianrasor.core.enable = true;

  sebastianrasor.acme.enable = true;
  sebastianrasor.actual.enable = true;
  sebastianrasor.authentik.enable = true;
  sebastianrasor.frigate.enable = false;
  sebastianrasor.homebox.enable = true;
  sebastianrasor.immich.enable = true;
  sebastianrasor.intel-arc-a380.enable = true;
  sebastianrasor.jellyfin.enable = true;
  sebastianrasor.nginx.enable = true;
  sebastianrasor.nut.enable = true;
  sebastianrasor.persistence.enable = true;
  sebastianrasor.postgresql.enable = true;
  sebastianrasor.radicale.enable = true;
  sebastianrasor.systemd-boot.enable = true;

  sebastianrasor.unas = {
    enable = true;
    host = "unas-pro.internal";
  };

  imports =
    [
      ./hardware-configuration.nix
    ]
    ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "25.05";
}
