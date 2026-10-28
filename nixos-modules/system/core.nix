{ constants, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.core;
in
{
  options.sebastianrasor.core = {
    enable = lib.mkEnableOption "core configuration";
  };

  config = lib.mkIf cfg.enable {
    sebastianrasor = {
      hjem.enable = lib.mkDefault true;
      nh.enable = lib.mkDefault true;
      nix.enable = lib.mkDefault true;
      nixpkgs.enable = lib.mkDefault true;
      pam.enable = lib.mkDefault true;
      secrets.enable = lib.mkDefault true;
      ssh = {
        enable = lib.mkDefault true;
        addSshKeysToUsers = [ "sebastian" ];
      };
      sshd.enable = lib.mkDefault true;
      systemd-networkd.enable = lib.mkDefault true;
      tailscale.enable = lib.mkDefault true;

      persistence = {
        directories = [
          "/var/lib/nixos"
          {
            directory = "/var/lib/private";
            mode = "0700";
          }
          "/var/lib/systemd/coredump"
          "/var/log"
        ];
        files = [
          "/etc/machine-id"
        ];
      };
    };

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = lib.mkDefault (!config.sebastianrasor.lanzaboote.enable);
        efi.canTouchEfiVariables = lib.mkDefault true;
      };
    };

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };

    security = {
      sudo-rs.enable = true;
      tpm2 = {
        enable = true;
        pkcs11.enable = true;
        tctiEnvironment.enable = true;
      };
    };

    services = {
      resolved = {
        enable = true;
        settings.Resolve = {
          fallbackDns = [
            "8.8.8.8"
            "8.8.4.4"
            "2001:4860:4860::8888"
            "2001:4860:4860::8844"
          ];
          MulticastDNS = true;
          LLMNR = false;
        };
      };
      timesyncd = {
        enable = true;
        servers = [ ];
        fallbackServers = [ "time.google.com" ];
      };
    };

    time.timeZone = lib.mkIf (!config.services.automatic-timezoned.enable) "America/Chicago";
    users.mutableUsers = false;
    users.users = {
      root = {
        hashedPassword = "!";
        openssh.authorizedKeys.keys = [
          constants.deploySshPublicKey
        ];
      };
      sebastian = {
        isNormalUser = true;
        home = "/home/sebastian";
        description = "Sebastian Rasor";
        extraGroups = [
          "tss"
          "wheel"
        ];
      };
    };
  };
}
