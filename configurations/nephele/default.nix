{...}: {
  networking.hostName = "nephele";

  sebastianrasor.core.enable = true;

  sebastianrasor.authentik-public-proxy.enable = true;
  sebastianrasor.acme.enable = true;
  sebastianrasor.checkemail.enable = true;
  sebastianrasor.headscale.enable = true;
  sebastianrasor.immich-public-proxy.enable = true;
  sebastianrasor.nginx.enable = true;
  sebastianrasor.persistence.enable = true;
  sebastianrasor.systemd-boot.enable = true;
  sebastianrasor.tailscale.exitNode = true;

  imports =
    [
      ./hardware-configuration.nix
    ]
    ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "25.05";
}
