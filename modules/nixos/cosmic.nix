{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.cosmic;
in
{
  options.sebastianrasor.cosmic = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    # I don't actually mind that gnome-keyring is enabled, but I have to disable it until cosmic-session fixes SSH:
    # https://github.com/pop-os/cosmic-session/issues/148
    services.gnome.gnome-keyring.enable = false;

    environment.systemPackages = with pkgs; [
      ffmpegthumbnailer
      wl-clipboard
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      COSMIC_DISABLE_DIRECT_SCANOUT = "true";
    };
  };
}
