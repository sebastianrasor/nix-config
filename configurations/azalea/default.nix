{
  lib,
  nixos-hardware,
  pkgs,
  ...
}:
{
  networking.hostName = "azalea";

  sebastianrasor.core.enable = true;
  sebastianrasor.avahi.enable = true;
  sebastianrasor.cosmic.enable = true;
  sebastianrasor.dvorak.enable = true;
  sebastianrasor.lanzaboote.enable = true;
  sebastianrasor.makemkv.enable = true;
  sebastianrasor.pipewire.enable = true;
  sebastianrasor.plymouth.enable = true;
  sebastianrasor.steam.enable = true;
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
  networking.timeServers = [ "time.google.com" ];

  imports = [
    nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
  ] ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "23.11";
}
