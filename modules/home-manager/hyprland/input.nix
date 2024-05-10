{ ... }: {
  wayland.windowManager.hyprland = {
    settings = {
      device = [
        {
          name = "pixa3854:00-093a:0274-touchpad";
          accel_profile = "adaptive";
        }
        {
          name = "symbol-technologies,-inc,-2008-symbol-bar-code-scanner";
          kb_variant = "";
        }
      ];
      input = {
        accel_profile = "flat";
      };
      monitor = [
        "desc:Dell Inc. DELL P2723DE 996FLW3,preferred,-716x-720,2"
        "desc:Dell Inc. DELL P2723DE 6ZRQCN3,preferred,564x-720,2"
        "eDP-1,preferred,0x0,2"
      ];
    };
  };
}
