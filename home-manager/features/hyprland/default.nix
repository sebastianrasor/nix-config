{ pkgs, config, inputs, ... }: {
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  xdg.portal = { 
    enable = true;
    configPackages = [
      pkgs.hyprland
    ];
    config = { 
      common = { 
        default = [ "hyprland" ];
      };
    };
    extraPortals = [ 
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      bindm = [
        "SUPER,mouse:272,movewindow"
      ];
      bind = [
        "ALT, Tab, focusCurrentOrLast,"
        "SUPER, Tab, focusCurrentOrLast,"

        "SUPER_SHIFT, Q, killactive,"
        "SUPER_SHIFT, R, exec, hyprctl reload"
        "SUPER_SHIFT, E, exit,"

        "SUPER, L, exec, ${pkgs.systemd}/bin/loginctl lock-session"

        "SUPER_SHIFT, H, movewindow, l"
        "SUPER_SHIFT, L, movewindow, r"
        "SUPER_SHIFT, K, movewindow, u"
        "SUPER_SHIFT, J, movewindow, d"
        "SUPER_SHIFT, left, movewindow, l"
        "SUPER_SHIFT, right, movewindow, r"
        "SUPER_SHIFT, up, movewindow, u"
        "SUPER_SHIFT, down, movewindow, d"

        "SUPER, H, movefocus, l"
        "SUPER, L, movefocus, r"
        "SUPER, K, movefocus, u"
        "SUPER, J, movefocus, d"
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"

        "SUPER_SHIFT, Space, togglefloating,"

        ", xf86audioraisevolume, exec, wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%+"
        ", xf86audiolowervolume, exec, wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%-"
        ", xf86audiomute, exec, wpctl set-mute @DEFAULT_SINK@ toggle"
      ]
      ++ (
        # workspaces
        # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
        builtins.concatLists (builtins.genList (
            x: let
              ws = let
                c = (x + 1) / 10;
              in
                builtins.toString (x + 1 - (c * 10));
            in [
              "SUPER, ${ws}, workspace, ${toString (x + 1)}"
              "SUPER_SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
            ]
          )
          10)
      );
      input = {
        kb_layout = "us";
        kb_variant = "${config.home.keyboard.variant}";
      };
      dwindle = {
        no_gaps_when_only = true;
      };
      misc = {
        exec-once="${pkgs.wpaperd}/bin/wpaperd";
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        enable_swallow = true;
        swallow_regex = "^(footclient)$";
      };
      animations = {
        enabled = true;
        animation = [
          "global, 1, 2, default"
        ];
      };
    };
  };
}
