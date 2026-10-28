_:
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
            LLMR = false;
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
          # deployment key
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBkrE2bWnp2A0RmoNxwMMtEAwi9kplYp7kJ+YxAHnF9"
          ];
        };
        sebastian = {
          isNormalUser = true;
          home = "/home/sebastian";
          description = "Sebastian Rasor";
          extraGroups = [
            "tss"
            "wheel"
          ]
          ++ lib.optionals cfg.laptop [ "dialout" ]
          ++ lib.optionals config.sebastianrasor.printing.enable [ "lp" ]
          ++ lib.optionals config.sebastianrasor.networkmanager.enable [ "networkmanager" ]
          ++ lib.optionals config.sebastianrasor.sane.enable [ "scanner" ];
        };
      };
    })
    (lib.mkIf cfg.laptop {
      sebastianrasor = {
        cosmic.enable = lib.mkDefault true;
        lanzaboote.enable = lib.mkDefault true;
        networkmanager.enable = lib.mkDefault true;
        persistence = {
          enable = lib.mkDefault true;
          directories = [
            "/var/lib/bluetooth"
            "/var/lib/boltd"
          ];
        };
        pipewire.enable = lib.mkDefault true;
        plymouth.enable = lib.mkDefault true;
        printing.enable = lib.mkDefault true;
        sane.enable = lib.mkDefault true;
        yubikey.enable = lib.mkDefault true;
      };

      console = {
        earlySetup = true;
        keyMap = "dvorak";
      };

      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = lib.mkForce false;
        };
        logitech.wireless.enable = true;
      };

      programs.solaar.enable = true;

      networking.networkmanager.wifi.powersave = true;
      services = {
        automatic-timezoned.enable = true;
        fwupd.enable = true;
        hardware.bolt.enable = true;
        logind.settings.Login =
          let
            suspendBehavior = "suspend-then-hibernate";
          in
          {
            HandleLidSwitch = suspendBehavior;
            HandlePowerKey = suspendBehavior;
            HandlePowerKeyLongPress = "poweroff";
          };
        xserver.xkb.layout = "dvorak";
      };
      systemd.network.wait-online.enable = false;
      systemd.sleep.settings.Sleep.HibernateDelaySec = "30m";
    })
  ];
}
