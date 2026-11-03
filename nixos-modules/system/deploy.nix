{ constants, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.deploy;
  hostName = config.networking.hostName;
  localNatsUrl = "nats://127.0.0.1:${toString config.services.nats.port}";
  serverUrl = if cfg.server.enable then localNatsUrl else "nats://deploy.ts.${constants.domain}:4222";

  deploySwitch = pkgs.writeShellApplication {
    name = "deploy-switch";
    runtimeEnv = config.nix.envVars // {
      HOME = "/root";
    };
    runtimeInputs = [
      pkgs.natscli
      config.nix.package.out
      config.system.build.nixos-rebuild
    ];
    text = ''
      store_path="$1"
      suffix="$2"

      nats --server="${serverUrl}" kv put status "${hostName}" "in_progress $store_path$suffix"$'\n' || true
      if nix-store --realise "$store_path" && nixos-rebuild switch --store-path "$store_path"; then
        nats --server="${serverUrl}" kv put status "${hostName}" "succeeded $store_path$suffix"$'\n' || true
        exit 0
      fi
      nats --server="${serverUrl}" kv put status "${hostName}" "failed $store_path$suffix"$'\n' || true
      exit 1
    '';
  };
in
{
  options.sebastianrasor.deploy = {
    server.enable = lib.mkEnableOption "NixOS deployment NATS server";
    client.enable = lib.mkEnableOption "pull-based NATS NixOS deployment agent";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.server.enable {
      services.nats = {
        enable = true;
        jetstream = true;
      };

      environment.systemPackages = [ pkgs.natscli ];

      sebastianrasor.persistence.directories = [
        {
          directory = config.services.nats.dataDir;
          inherit (config.services.nats) user group;
          mode = "0750";
        }
      ];
    })

    (lib.mkIf cfg.client.enable {
      systemd.services.deploy-client = {
        description = "NixOS pull-based NATS deployment agent";
        after = [
          "network-online.target"
          "tailscaled.service"
        ]
        ++ lib.optionals cfg.server.enable [ "nats.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.StartLimitIntervalSec = 0;

        path = [ pkgs.natscli ];

        script = ''
          wait_for_switch() {
            while :; do
              case "$(systemctl is-active deploy-switch.service || true)" in
                active | activating | deactivating) sleep 1 ;;
                *) break ;;
              esac
            done
          }

          while IFS= read -r line; do
            read -r store_path meta <<< "$line" || true
            [[ "$store_path" == /nix/store/* ]] || continue
            suffix="''${meta:+ $meta}"

            wait_for_switch

            if [ "$(readlink -f /run/current-system)" = "$store_path" ]; then
              current_status=$(nats --server="${serverUrl}" kv get status "${hostName}" --raw 2>/dev/null || true)
              case "$current_status" in
                "succeeded $store_path$suffix" | "failed $store_path$suffix") ;;
                *) nats --server="${serverUrl}" kv put status "${hostName}" "succeeded $store_path$suffix"$'\n' || true ;;
              esac
              continue
            fi

            systemd-run --collect --unit=deploy-switch ${lib.getExe deploySwitch} "$store_path" "$suffix" || true
            wait_for_switch
          done < <(
            nats --server="${serverUrl}" sub "\$KV.configs.${hostName}" \
              --stream=KV_configs --last-per-subject --raw
          )
        '';

        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
        };
      };
    })
  ];
}
