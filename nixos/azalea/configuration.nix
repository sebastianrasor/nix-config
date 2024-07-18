# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, outputs, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      outputs.nixosModules.brillo
      outputs.nixosModules.dvorak
      outputs.nixosModules.hyprland
      outputs.nixosModules.hyprlock
      outputs.nixosModules.linux-latest
      outputs.nixosModules.opengl
      outputs.nixosModules.pipewire
      outputs.nixosModules.ratbagd
      outputs.nixosModules.steam
      outputs.nixosModules.yubikey
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "azalea"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sebastian = {
    isNormalUser = true;
    description = "Sebastian Rasor";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs; [];
  };

  nix.settings.allowed-users = [ "sebastian" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    polkit-kde-agent
    qt6.qtwayland
    vim
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
  ];

  #xdg.portal = {
  #  enable = true;
  #  extraPortals = [
  #    pkgs.xdg-desktop-portal-gtk
  #  ];
  #};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  services.power-profiles-daemon.enable = true;

  powerManagement.enable = true;

  #services.logind = {
  #  lidSwitch = "suspend-then-hibernate";
  #  extraConfig = ''
  #    HandlePowerKey=suspend-then-hibernate
  #  '';
  #};
  #systemd.sleep.extraConfig =
  #  ''
  #    HibernateDelaySec=60m
  #    SuspendState=mem
  #  '';

  documentation.nixos.enable = false;

  system.stateVersion = "23.11";

}
