_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.laptop;
in
{
  options.sebastianrasor.laptop = {
    enable = lib.mkEnableOption "laptop configuration";
  };

  config = lib.mkIf cfg.enable {
    sebastianrasor = {
      core.enable = lib.mkDefault true;
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

    users.users.sebastian.extraGroups = [ "dialout" ];

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
  };
}
