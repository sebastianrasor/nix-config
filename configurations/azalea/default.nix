{
  inputs,
  lib,
  pkgs,
  ...
}: {
  networking.hostName = "azalea";

  sebastianrasor.core.enable = true;
  sebastianrasor.cosmic.enable = true;
  sebastianrasor.dvorak.enable = true;
  sebastianrasor.fwupd.enable = true;
  sebastianrasor.lanzaboote.enable = true;
  sebastianrasor.makemkv.enable = true;
  sebastianrasor.networkmanager.enable = true;
  sebastianrasor.pipewire.enable = true;
  sebastianrasor.plymouth.enable = true;
  sebastianrasor.steam.enable = true;
  sebastianrasor.tailscale.enable = true;
  sebastianrasor.yubikey.enable = true;

  sebastianrasor.unas = {
    enable = true;
    host = "unas-pro.localdomain";
  };
  sebastianrasor.unas-lazy-media.enable = true;

  time.timeZone = "America/Chicago";
  hardware.bluetooth.powerOnBoot = lib.mkForce false;
  hardware.graphics.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  nixpkgs.config.allowUnfree = true;
  networking.timeServers = ["time.google.com"];
  environment.systemPackages = with pkgs; [
    framework-tool
    fw-ectool
  ];

  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/sbctl"
      "/var/lib/nixos"
      "/var/lib/bluetooth"
      "/var/lib/systemd/coredump"
      "/var/log"
      "/home"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/var/lib/tailscale/tailscaled.state"
    ];
  };

  imports =
    [
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
      ./hardware-configuration.nix
    ]
    ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "23.11";
}
