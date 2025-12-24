{ config, ... }:
{
  networking.hostName = "carbon";

  sebastianrasor.core.enable = true;

  sebastianrasor.acme.enable = true;
  sebastianrasor.actual.enable = true;
  sebastianrasor.authentik.enable = true;
  sebastianrasor.frigate.enable = false;
  sebastianrasor.gate.enable = true;
  sebastianrasor.homebox.enable = true;
  sebastianrasor.immich.enable = true;
  sebastianrasor.intel-arc-a380.enable = true;
  sebastianrasor.jellyfin.enable = true;
  sebastianrasor.minecraft-server.enable = true;
  sebastianrasor.minecraft-world-backup.enable = true;
  sebastianrasor.persistence.enable = true;
  sebastianrasor.postgresql.enable = true;
  sebastianrasor.radicale.enable = true;
  sebastianrasor.reverse-proxy = {
    enable = true;
    baseDomainName = "ts.${config.sebastianrasor.domain}";
  };
  sebastianrasor.systemd-boot.enable = true;
  sebastianrasor.systemd-networkd.interfacesRequiredForOnline."enp10s0f0np0" = "routable";
  sebastianrasor.tailscale-golink.enable = true;

  sebastianrasor.unas = {
    enable = true;
    host = "10.0.0.103";
  };

  imports = [
    ./hardware-configuration.nix
  ]
  ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "25.05";
}
