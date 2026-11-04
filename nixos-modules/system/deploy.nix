{ constants, self, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.deploy;
  inherit (config.networking) hostName;
  localNatsUrl = "nats://127.0.0.1:${toString config.services.nats.port}";
  serverUrl = if cfg.server.enable then localNatsUrl else "nats://deploy.ts.${constants.domain}:4222";
  peerHosts = builtins.filter (h: h != hostName) (builtins.attrNames self.nixosConfigurations);

  deploySwitch = pkgs.writeShellApplication {
    name = "deploy-switch";
    runtimeEnv = config.nix.envVars // {
      HOME = "/root";
    };
    runtimeInputs = [
      pkgs.natscli
      config.nix.package.out
      config.system.build.nixos-rebuild
    ]
    ++ config.systemd.defaultPath;
    text = ''
      store_path="$1"
      suffix="$2"

      put_status() {
        local value="$1"
        for _ in {1..15}; do
          if nats --server="${serverUrl}" kv put status "${hostName}" "$value"$'\n' >/dev/null; then
            return 0
          fi
          sleep 2
        done
        return 1
      }

      realise_closure() {
        for _ in {1..6}; do
          if nix-store --realise "$store_path"; then
            return 0
          fi
          echo "Retrying nix-store --realise in 5s..." >&2
          sleep 5
        done
        return 1
      }

      switch_system() {
        if nixos-rebuild switch --store-path "$store_path"; then
          return 0
        fi
        echo "Initial nixos-rebuild switch failed; retrying in 15s..." >&2
        sleep 15
        nixos-rebuild switch --store-path "$store_path"
      }

      put_status "in_progress $store_path$suffix" || true
      ${lib.optionalString (cfg.server.enable && peerHosts != [ ]) ''
        sleep 5
        for _ in {1..150}; do
          peers_busy=0
          for peer in ${lib.escapeShellArgs peerHosts}; do
            peer_target=""
            read -r peer_target _ < <(
              nats --server="${serverUrl}" kv get configs "$peer" --raw 2>/dev/null || true
            ) || true
            peer_state=""
            peer_path=""
            read -r peer_state peer_path _ < <(
              nats --server="${serverUrl}" kv get status "$peer" --raw 2>/dev/null || true
            ) || true
            if [ -n "$peer_target" ] && [ "$peer_state" = "in_progress" ] && [ "$peer_path" = "$peer_target" ]; then
              peers_busy=1
              break
            fi
          done
          [ "$peers_busy" -eq 0 ] && break
          sleep 2
        done
      ''}
      if realise_closure && switch_system; then
        put_status "succeeded $store_path$suffix" || true
        exit 0
      fi
      put_status "failed $store_path$suffix" || true
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
      services = {
        nats = {
          enable = true;
          jetstream = true;
        };

        headscale.settings.dns.extra_records = lib.mkIf config.sebastianrasor.headscale.enable [
          {
            name = "deploy.ts.${constants.domain}";
            type = "A";
            value = "100.64.0.3";
          }
        ];
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
          put_status() {
            local value="$1"
            for _ in {1..15}; do
              if nats --server="${serverUrl}" kv put status "${hostName}" "$value"$'\n' >/dev/null; then
                return 0
              fi
              sleep 2
            done
            return 1
          }

          wait_for_switch() {
            while :; do
              case "$(systemctl is-active deploy-switch.service || true)" in
                active | activating | deactivating) sleep 1 ;;
                *) break ;;
              esac
            done
          }

          while :; do
            while IFS= read -r line; do
              read -r store_path meta <<< "$line" || true
              [[ "$store_path" == /nix/store/* ]] || continue
              suffix="''${meta:+ $meta}"

              wait_for_switch

              current_status=$(nats --server="${serverUrl}" kv get status "${hostName}" --raw 2>/dev/null || true)
              if [ "$current_status" = "failed $store_path$suffix" ]; then
                continue
              fi

              if [[ "$current_status" != "failed $store_path" && "$current_status" != "failed $store_path "* ]] \
                && [ "$(readlink -f /run/current-system)" = "$store_path" ]; then
                if [ "$current_status" != "succeeded $store_path$suffix" ]; then
                  put_status "succeeded $store_path$suffix" || true
                fi
                continue
              fi

              systemd-run --collect --unit=deploy-switch ${lib.getExe deploySwitch} "$store_path" "$suffix" || true
              wait_for_switch
            done < <(
              nats --server="${serverUrl}" sub "\$KV.configs.${hostName}" \
                --stream=KV_configs --last-per-subject --wait=5m --raw || true
            )
            sleep 2
          done
        '';

        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
        };
      };
    })
  ];
}
