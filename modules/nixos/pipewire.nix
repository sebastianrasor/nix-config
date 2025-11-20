{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.pipewire.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.pipewire.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
