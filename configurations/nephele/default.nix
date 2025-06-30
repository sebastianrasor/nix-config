# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{...}: {
  networking.hostName = "nephele";
  time.timeZone = "America/Chicago";
  networking.timeServers = ["time.google.com"];

  sebastianrasor.acme.enable = true;
  sebastianrasor.headscale.enable = true;
  sebastianrasor.home-manager.enable = true;
  sebastianrasor.nginx.enable = true;
  sebastianrasor.nix.enable = true;
  sebastianrasor.sshd.enable = true;
  sebastianrasor.sudo.enable = true;

  imports =
    [
      ./hardware-configuration.nix
    ]
    ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  nix.extraOptions = ''
    build-dir = /nix/persist/nix-daemon
  '';

  nixpkgs.config.allowUnfree = true;

  environment.etc."machine-id".source = "/nix/persist/etc/machine-id";
  environment.etc."ssh/ssh_host_rsa_key".source = "/nix/persist/etc/ssh/ssh_host_rsa_key";
  environment.etc."ssh/ssh_host_rsa_key.pub".source = "/nix/persist/etc/ssh/ssh_host_rsa_key.pub";
  environment.etc."ssh/ssh_host_ed25519_key".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
  environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.05";
}
