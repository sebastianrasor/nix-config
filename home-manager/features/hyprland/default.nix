{ pkgs, config, ... }: {
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  xdg.portal = { 
    enable = true;
    config = { 
      common = { 
        default = [ 
          "hyprland"
        ];
      };
    };
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      bind = [
        "SUPER, C, killactive,"
        "SUPER_SHIFT, Escape, exit,"
        ", Print, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp -d)\" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png"
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
        swallow_regex = "^(foot)$";
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
