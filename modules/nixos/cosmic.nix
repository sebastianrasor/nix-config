{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.cosmic.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.cosmic.enable {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

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
