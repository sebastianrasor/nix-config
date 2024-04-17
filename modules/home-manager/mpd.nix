{ ... }: {
  services.mpd = {
    enable = true;
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "My Pipewire output"
      }
    '';
  };
  services.mpdris2.enable = true;
  services.mpd-discord-rpc.enable = true;
}
