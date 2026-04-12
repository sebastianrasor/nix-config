{
  config,
  constants,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.hydra;
  secretsEnabled = config.sebastianrasor.secrets.enable;
in
{
  options.sebastianrasor.hydra = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.hydra = {
      enable = true;
      hydraURL = "hydra.${config.sebastianrasor.reverse-proxy.baseDomainName}";
      listenHost = "localhost";
      notificationSender = "hydra@${constants.domain}";
      useSubstitutes = true;
      extraConfig = ''
        Import ${config.sops.secrets."hydra-github-authorization".path}
        <dynamicruncommand>
          enable = 1
        </dynamicruncommand>
        <githubstatus>
          jobs = nix-config:nix-config:.*
          useShortContext = true
        </githubstatus>
      '';
    };

    sebastianrasor.reverse-proxy.proxies."hydra" =
      "http://${config.services.hydra.listenHost}:${toString config.services.hydra.port}";

    sops.secrets."hydra-github-authorization" = lib.mkIf secretsEnabled {
      owner = "hydra-queue-runner";
      group = "hydra";
    };
  };
}
