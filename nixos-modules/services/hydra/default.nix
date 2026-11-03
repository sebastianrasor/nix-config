{ constants, self, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.hydra;
  natsUrl = "nats://127.0.0.1:${toString config.services.nats.port}";
  hydraApi = "http://${config.services.hydra.listenHost}:${toString config.services.hydra.port}";
  ghDeploymentsUrl = "https://api.github.com/repos/sebastianrasor/nix-config/deployments";
  ghHeaders = config.sops.templates."hydra/github-headers".path;

  notifyDeploy = pkgs.writeShellApplication {
    name = "hydra-notify-deploy";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      pkgs.natscli
    ];
    text = ''
      read -r build_id host store_path < <(
        jq -r '
          select(.buildStatus == 0)
          | [(.build // .id), (.job | ltrimstr("nixosConfigurations.")), (.outputs[] | select(.name == "out") | .path)]
          | @tsv
        ' "$HYDRA_JSON"
      ) || exit 0

      read -r current_path _ < <(
        nats --server="${natsUrl}" kv get configs "$host" --raw 2>/dev/null || true
      ) || true
      if [ "$current_path" = "$store_path" ]; then
        echo "Skipping $host: $store_path already published to NATS"
        exit 0
      fi

      eval_id=$(
        curl --retry 3 -fsSL -H "Accept: application/json" "${hydraApi}/build/$build_id" \
          | jq -r '.jobsetevals | max // empty'
      ) || eval_id=""

      rev=""
      if [ -n "$eval_id" ]; then
        rev=$(
          curl --retry 3 -fsSL -H "Accept: application/json" "${hydraApi}/eval/$eval_id" \
            | jq -r '(.flake // "" | try capture("(?<rev>[0-9a-f]{40})").rev) // empty'
        ) || rev=""
      fi

      deployment_id=$(
        jq -n \
          --arg ref "''${rev:-main}" \
          --arg env "$host" \
          --arg desc "$store_path" \
          '{ref: $ref, environment: $env, auto_merge: false, required_contexts: [], description: $desc}' \
        | curl --retry 3 -fsSL -X POST -H "@${ghHeaders}" "${ghDeploymentsUrl}" -d @- \
        | jq -r '.id // empty'
      ) || deployment_id=""

      if [ -n "$deployment_id" ]; then
        jq -n --arg url "${config.services.hydra.hydraURL}/build/$build_id" \
          '{state: "queued", log_url: $url}' \
        | curl --retry 3 -fsSL -X POST -H "@${ghHeaders}" \
            "${ghDeploymentsUrl}/$deployment_id/statuses" -d @- >/dev/null || true
      fi

      nats --server="${natsUrl}" kv put configs "$host" \
        "$store_path''${deployment_id:+ $deployment_id $build_id}"$'\n' >/dev/null
      echo "Published $host -> $store_path (ref=''${rev:-main}, deployment=''${deployment_id:-none})"
    '';
  };
in
{
  options.sebastianrasor.hydra = {
    enable = lib.mkEnableOption "hydra";
  };

  config = lib.mkIf cfg.enable {
    services = {
      hydra = {
        enable = true;
        hydraURL = "https://hydra.${config.sebastianrasor.reverse-proxy.baseDomainName}";
        listenHost = "127.0.0.1";
        notificationSender = "hydra@${constants.domain}";
        useSubstitutes = true;
        extraConfig = ''
          Include ${config.sops.templates."hydra/secrets.conf".path}
          local_auth_enabled = 0
          <oidc>
            <provider authentik>
              display_name = "Authentik"
              discovery_url = "https://authentik.${constants.domain}/application/o/hydra/.well-known/openid-configuration"
              client_id = "9HU3wP6aMT3naM6vLC4WuSJSUaOstPTUoIpD1ppq"
              client_secret_file = "${config.sops.secrets."oidc/clientSecrets/hydra".path}"
              extra_scopes = "groups"
              role_claim = "groups"
              <role_mapping>
                hydra-admins = admin
                hydra-admins = bump-to-front
                hydra-admins = cancel-build
                hydra-admins = create-projects
                hydra-admins = eval-jobset
                hydra-admins = restart-jobs
              </role_mapping>
            </provider>
          </oidc>
          <githubstatus>
            jobs = nix-config:(main|pr-.*):required
            context = ci/hydra:required
            excludeBuildFromContext = 1
          </githubstatus>
          <githubstatus>
            jobs = nix-config:(main|pr-.*):(?!required$).+
            excludeBuildFromContext = 1
            useShortContext = 1
          </githubstatus>
          ${lib.concatMapStringsSep "\n" (host: ''
            <runcommand>
              job = nix-config:main:nixosConfigurations.${host}
              command = ${lib.getExe notifyDeploy}
            </runcommand>
          '') (builtins.attrNames self.nixosConfigurations)}
        '';
      };

      hydra-builder = {
        enable = true;
        queueRunnerAddr = "http://[::1]:${toString config.services.hydra.queueRunner.grpc.port}";
      };

      nginx.virtualHosts."hydra-webhook.${constants.domain}".locations = {
        "/".return = "444";
        "= /api/push-github" = {
          proxyPass = "${hydraApi}/api/push-github";
          extraConfig = ''
            client_max_body_size 10M;
          '';
        };
      };
    };

    systemd.services = {
      hydra-init = {
        stopIfChanged = false;
        unitConfig.RequiresMountsFor = [ "/var/lib/hydra" ];
      };
      hydra-builder = {
        after = [
          "hydra-init.service"
          "hydra-queue-runner.service"
        ];
        requires = [ "hydra-init.service" ];
      };
      hydra-server.after = [ "authentik.service" ];
      hydra-notify.after = [ "nats.service" ];

      hydra-deploy-status = {
        description = "Forward NATS NixOS deployment statuses to GitHub Deployments";
        after = [
          "network-online.target"
          "nats.service"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.StartLimitIntervalSec = 0;

        path = [
          pkgs.curl
          pkgs.jq
          pkgs.natscli
        ];

        script = ''
          while IFS= read -r line; do
            read -r state _ deployment_id build_id <<< "$line" || true
            [[ "$deployment_id" =~ ^[0-9]+$ ]] || continue

            case "$state" in
              in_progress) gh_state="in_progress" ;;
              succeeded)   gh_state="success" ;;
              failed)      gh_state="failure" ;;
              *)           continue ;;
            esac

            last_state=$(
              curl --retry 3 -fsSL -H "@${ghHeaders}" \
                "${ghDeploymentsUrl}/$deployment_id/statuses?per_page=100" \
              | jq -r '(max_by(.id) | .state) // empty'
            ) || continue
            [ "$last_state" != "$gh_state" ] || continue

            log_url="${config.services.hydra.hydraURL}''${build_id:+/build/$build_id}"
            jq -n --arg state "$gh_state" --arg url "$log_url" \
              '{state: $state, log_url: $url}' \
            | curl --retry 3 -fsSL -X POST -H "@${ghHeaders}" \
                "${ghDeploymentsUrl}/$deployment_id/statuses" -d @- >/dev/null || true
          done < <(
            nats --server="${natsUrl}" sub "\$KV.status.*" \
              --stream=KV_status --last-per-subject --raw
          )
        '';

        serviceConfig = {
          User = "hydra";
          Group = "hydra";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };

    sebastianrasor = {
      deploy.server.enable = lib.mkDefault true;

      persistence.directories = [
        {
          directory = "/var/lib/hydra";
          user = "hydra";
          group = "hydra";
          mode = "0750";
        }
      ];

      reverse-proxy.proxies = {
        "hydra" = hydraApi;
        "hydra-webhook.${constants.domain}".public = true;
      };
    };

    sops = {
      secrets = {
        "github/personalAccessTokens/hydra" = { };
        "github/webhookSecrets/hydra" = { };
        "oidc/clientSecrets/hydra".owner = "hydra-www";
      };
      templates = {
        "hydra/github-headers" = {
          content = ''
            Accept: application/vnd.github+json
            Authorization: Bearer ${config.sops.placeholder."github/personalAccessTokens/hydra"}
            X-GitHub-Api-Version: 2022-11-28
          '';
          owner = "hydra";
          group = "hydra";
          mode = "0440";
        };
        "hydra/secrets.conf" = {
          content = ''
            <github_authorization>
              sebastianrasor = Bearer ${config.sops.placeholder."github/personalAccessTokens/hydra"}
            </github_authorization>
            <webhooks>
              <github>
                secret = ${config.sops.placeholder."github/webhookSecrets/hydra"}
              </github>
            </webhooks>
          '';
          owner = "hydra";
          group = "hydra";
          mode = "0440";
        };
      };
    };
  };
}
