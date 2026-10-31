_: _: {
  networking.hostName = "nephele";

  sebastianrasor = {
    core.enable = true;

    persistence.enable = true;
    sshd.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIISaqWRMez2mFczqhMmiYe0KzNeENKsqEQw/AsOC+Ay+";
    tailscale.exitNode = true;
    systemd-networkd.interfacesRequiredForOnline."enp1s0" = "routable";
    wireguard = {
      enable = true;
      address = "10.100.0.1/24";
      listenPort = 51820;
      publicKey = "OUZdlRDtvsgRhfMrVgMsFtF4Sa70pSVH5hJ6RF3G4yU=";
    };
  };

  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.05";
}
