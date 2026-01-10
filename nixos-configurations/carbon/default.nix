{ config, ... }:
{
  networking.hostName = "carbon";

  sebastianrasor = {
    core.enable = true;

    acme.enable = true;
    actual.enable = true;
    authentik.enable = true;
    frigate.enable = false;
    gate.enable = true;
    homebox.enable = true;
    immich.enable = true;
    intel-arc-a380.enable = true;
    jellyfin.enable = true;
    minecraft-server.enable = true;
    minecraft-world-backup.enable = true;
    paperless.enable = true;
    persistence.enable = true;
    postgresql.enable = true;
    radicale.enable = true;
    reverse-proxy = {
      enable = true;
      baseDomainName = "ts.${config.sebastianrasor.domain}";
    };
    systemd-boot.enable = true;
    systemd-networkd.interfacesRequiredForOnline."enp10s0f0np0" = "routable";
    tailscale-golink.enable = true;
    unas = {
      enable = true;
      host = "10.0.0.103";
    };
  };

  imports = [
    ./hardware-configuration.nix
  ]
  ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "25.05";
}
