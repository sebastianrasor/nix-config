{ constants, ... }:
_: {
  networking.hostName = "carbon";

  sebastianrasor = {
    core.enable = true;

    acme.enable = true;
    actual.enable = true;
    authentik.enable = true;
    cheaters-swear-jar.enable = true;
    forgejo.enable = true;
    harmonia.enable = true;
    homebox.enable = true;
    immich.enable = true;
    intel-arc-a380.enable = true;
    jellyfin.enable = true;
    nixbot.enable = true;
    paperless.enable = true;
    persistence.enable = true;
    postgresql.enable = true;
    radicale.enable = true;
    reverse-proxy = {
      enable = true;
      baseDomainName = "ts.${constants.domain}";
    };
    sshd.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAGdZ/fyPx7w2GsbE337H0kNst+GWL/gN4piJizkWj/9";
    systemd-networkd.interfacesRequiredForOnline."enp10s0f0np0" = "routable";
    tailscale-golink.enable = true;
    unas = {
      enable = true;
      host = "10.0.0.103";
    };
    vaultwarden.enable = true;
  };

  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.05";
}
