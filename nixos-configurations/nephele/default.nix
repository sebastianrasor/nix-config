{ constants, ... }:
{
  config,
  ...
}:
{
  networking.hostName = "nephele";

  sebastianrasor = {
    core.enable = true;

    acme.enable = true;
    headscale.enable = true;
    persistence.enable = true;
    reverse-proxy = {
      enable = true;
      baseDomainName = constants.domain;
      openFirewall = true;
      proxies = {
        "authentik" = "https://authentik.ts.${constants.domain}";
        "immich" = "http://127.0.0.1:${toString config.services.immich-public-proxy.port}";
      };
    };
    sshd.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIISaqWRMez2mFczqhMmiYe0KzNeENKsqEQw/AsOC+Ay+";
    tailscale.exitNode = true;
    systemd-networkd.interfacesRequiredForOnline."enp1s0" = "routable";
    www-sebastianrasor-com.enable = true;
  };

  services = {
    immich-public-proxy = {
      enable = true;
      port = 3001;
      immichUrl = "https://immich.ts.${constants.domain}";
    };
  };

  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.05";
}
