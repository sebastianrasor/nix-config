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
  sebastianrasor.home-manager.enable = true;
  sebastianrasor.lanzaboote.enable = true;
  sebastianrasor.makemkv.enable = true;
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

  environment.etc."machine-id".source = "/nix/persist/etc/machine-id";
  environment.etc."ssh/ssh_host_rsa_key".source = "/nix/persist/etc/ssh/ssh_host_rsa_key";
  environment.etc."ssh/ssh_host_rsa_key.pub".source = "/nix/persist/etc/ssh/ssh_host_rsa_key.pub";
  environment.etc."ssh/ssh_host_ed25519_key".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
  environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";

  imports =
    [
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
      ./hardware-configuration.nix
    ]
    ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "23.11";
}
