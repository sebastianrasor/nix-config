{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.auto-upgrade;
in
{
  options.sebastianrasor.auto-upgrade = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "github:sebastianrasor/nix-config";
      runGarbageCollection = true;
    };

    systemd = {
      services = {
        nixos-upgrade-check = {
          description = "Check for NixOS Upgrade";

          after = [
            "network-online.target"
            "sleep.target"
          ];
          wantedBy = [ "sleep.target" ];

          restartIfChanged = false;
          unitConfig.X-StopOnRemoval = false;

          serviceConfig.Type = "oneshot";

          environment =
            config.nix.envVars
            // {
              inherit (config.environment.sessionVariables) NIX_PATH;
              HOME = "/root";
            }
            // config.networking.proxy.envVars;

          path = with pkgs; [
            coreutils
            hostname
            nix
          ];

          script = ''
            current_system="$(readlink -f /run/current-system)"
            repo_system="$(nix eval github:sebastianrasor/nix-config#nixosConfigurations.$(hostname -s).config.system.build.toplevel.outPath --raw)"
            if [ "$current_system" != "$repo_system" ]; then
              echo systemctl start nixos-upgrade.service
            fi
          '';
        };
        nixos-upgrade = {
          startAt = lib.mkForce [ ];
        };
      };
      timers.nixos-upgrade = {
        enable = false;
      };
    };
  };
}
