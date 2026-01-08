{ config, ... }:
{
  networking.hostName = "nephele";

  sebastianrasor = {
    core.enable = true;

    authentik-public-proxy.enable = true;
    acme.enable = true;
    checkemail.enable = true;
    gate.enable = true;
    headscale.enable = true;
    immich-public-proxy.enable = true;
    persistence.enable = true;
    reverse-proxy = {
      enable = true;
      baseDomainName = config.sebastianrasor.domain;
      openFirewall = true;
    };
    systemd-boot.enable = true;
    tailscale.exitNode = true;
    systemd-networkd.interfacesRequiredForOnline."enp1s0" = "routable";
  };

  imports = [
    ./hardware-configuration.nix
  ]
  ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "25.05";
}
