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

  sebastianrasor.user-root.enable = true;
  sebastianrasor.user-sebastian.enable = true;
  home-manager.users.sebastian = {
    sebastianrasor.atkinson-hyperlegible.enable = true;
    sebastianrasor.bottom.enable = true;
    sebastianrasor.discord.enable = true;
    sebastianrasor.fish.bashInit = false;
    sebastianrasor.git.enable = true;
    sebastianrasor.google-chrome.enable = true;
    sebastianrasor.gpg.enable = true;
    sebastianrasor.jellyfin-media-player.enable = true;
    sebastianrasor.monaspace.enable = true;
    sebastianrasor.mpv.enable = true;
    sebastianrasor.neovim.enable = true;
    sebastianrasor.pass.enable = true;
    sebastianrasor.thunderbird.enable = true;
  };

  time.timeZone = "America/Chicago";
  hardware.bluetooth.powerOnBoot = lib.mkForce false;
  hardware.graphics.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  nixpkgs.config.allowUnfree = true;
  networking.timeServers = [ "time.google.com" ];

  imports = [
    nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
  ];

  system.stateVersion = "23.11";
}
