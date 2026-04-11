{
  config,
  lib,
  outputs,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.deploy-client;
in
{
  options.sebastianrasor.deploy-client = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    websocket = lib.mkOption {
      type = lib.types.str;
      default = "wss://deploy.ts.rasor.us";
    };

    hydraURL = lib.mkOption {
      type = lib.types.str;
      default = outputs.nixosConfigurations.carbon.config.services.hydra.hydraURL;
    };

    hydraProjectId = lib.mkOption {
      type = lib.types.str;
      default = "nix-config";
    };

    hydraJobsetId = lib.mkOption {
      type = lib.types.str;
      default = "nix-config";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.deploy-client = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        curl
        nix
        jq
        websocat
      ];

      serviceConfig = {
        Restart = "always";
      };

      script =
        let
          latestSuccessfulBuildEndpoint = "${cfg.hydraURL}/job/${cfg.hydraProjectId}/${cfg.hydraJobsetId}/nixosConfigurations.${config.networking.hostName}/latest";
        in
        ''
          websocat -qnUt - "autoreconnect:${cfg.websocket}" | while read -r action; do
            case "$action" in
            switch | boot | test | dry-activate)
              echo "Received deploy request" >&2
              hydra_api_response="$(curl -sLH 'accept: application/json' "${latestSuccessfulBuildEndpoint}")"
              if ! latest_build_path="$(echo "$hydra_api_response" | jq -er '.buildoutputs.out.path')"; then
                echo "No deployment target available" >&2
                continue
              fi
              if [ "$(readlink -f /run/current-system)" != "$latest_build_path" ]; then
                nix-store -r "$latest_build_path"
                cmd=(
                  "systemd-run"
                  "-E" "LOCALE_ARCHIVE"
                  "--collect"
                  "--no-ask-password"
                  "--pty"
                  "--quiet"
                  "--same-dir"
                  "--service-type=exec"
                  "--unit=deploy-client-switch-to-configuration"
                  "--wait"
                  "$latest_build_path/bin/switch-to-configuration"
                )
                if ! "''${cmd[@]}" "$action"; then
                  echo "warning: error(s) occurred while switching to the new configuration" >&2
                fi
              else
                echo "Current system matches deployment target, no further action required" >&2
              fi
              ;;
            *) echo "Unknown action: $action" ;;
            esac
          done
        '';
    };
  };
}
