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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    laptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      sebastianrasor = {
        cachix-agent.enable = true;
        cachix-watch-store.enable = true;
        home-manager.enable = true;
        i18n.enable = true;
        nh.enable = true;
        nix.enable = true;
        pam.enable = true;
        secrets.enable = true;
        sshd.enable = true;
        sudo-rs.enable = true;
        systemd-networkd.enable = true;
        systemd-resolved.enable = true;
        systemd-timesyncd.enable = true;
        tailscale.enable = true;

        persistence = {
          directories = [
            "/var/lib/nixos"
            "/var/lib/private"
            "/var/lib/systemd/coredump"
            "/var/log"
          ];
          files = [
            "/etc/machine-id"
          ];
        };
      };

      system.activationScripts = {
        "createPersistentStorageDirs".deps = [
          "var-lib-private-permissions"
          "users"
          "groups"
        ];
        "var-lib-private-permissions" =
          let
            persistenceStoragePath = config.sebastianrasor.persistence.storagePath;
          in
          {
            deps = [ "specialfs" ];
            text = ''
              mkdir -p ${persistenceStoragePath}/var/lib/private
              chmod 0700 ${persistenceStoragePath}/var/lib/private
            '';
          };
      };

      boot.kernelPackages = pkgs.linuxPackages_latest;
      time.timeZone = lib.mkIf (!config.sebastianrasor.automatic-timezoned.enable) "America/Chicago";
      users.mutableUsers = false;
      users.users.root = {
        hashedPassword = "!";
        shell = pkgs.shadow;
      };
    })
    (lib.mkIf cfg.laptop {
      sebastianrasor = {
        automatic-timezoned.enable = true;
        bluetooth.enable = true;
        bolt.enable = true;
        cosmic.enable = true;
        dvorak.enable = true;
        fwupd.enable = true;
        lanzaboote.enable = true;
        logitech.enable = true;
        networkmanager.enable = true;
        persistence.enable = true;
        pipewire.enable = true;
        plymouth.enable = true;
        printing.enable = true;
        sane.enable = true;
        yubikey.enable = true;
      };
      boot.initrd.systemd.enable = true;
      networking.networkmanager.wifi.powersave = true;
      services.logind.settings.Login =
        let
          suspendBehavior = "suspend-then-hibernate";
        in
        {
          HandleLidSwitch = suspendBehavior;
          HandlePowerKey = suspendBehavior;
          HandlePowerKeyLongPress = "poweroff";
        };
      systemd.network.wait-online.enable = false;
      systemd.sleep.extraConfig = ''
        HibernateDelaySec=30m
      '';
    })
  ];
}
