{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.sebastianrasor.core = {
    enable = lib.mkEnableOption "";
    laptop = lib.mkEnableOption "";
  };

  config = lib.mkMerge [
    (lib.mkIf config.sebastianrasor.core.enable {
      sebastianrasor = {
        cachix-agent.enable = true;
        home-manager.enable = true;
        i18n.enable = true;
        nix.enable = true;
        pam.enable = true;
        secrets.enable = true;
        sshd.enable = true;
        sudo-rs.enable = true;
        tailscale.enable = true;

        persistence = {
          directories = [
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            "/var/log"
          ];
          files = [
            "/etc/machine-id"
          ];
        };
      };

      boot.kernelPackages = pkgs.linuxPackages_latest;
      networking = {
        timeServers = [ "pool.ntp.org" ];
        domain = config.sebastianrasor.domain;
        search = [ config.sebastianrasor.domain ];
      };
      time.timeZone = lib.mkIf (!config.sebastianrasor.automatic-timezoned.enable) "America/Chicago";
      users.mutableUsers = false;
      users.users.root = {
        hashedPassword = "!";
        shell = pkgs.shadow;
      };
    })
    (lib.mkIf config.sebastianrasor.core.laptop {
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
      systemd.sleep.extraConfig = ''
        HibernateDelaySec=30m
      '';
    })
  ];
}
