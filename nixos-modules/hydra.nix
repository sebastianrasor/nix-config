_:
{
  config,
  constants,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.hydra;
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
      hydraURL = "https://hydra.${config.sebastianrasor.reverse-proxy.baseDomainName}";
      listenHost = "localhost";
      notificationSender = "hydra@${constants.domain}";
      useSubstitutes = true;
      extraConfig = ''
        Include ${config.sops.templates."hydra/github_authorizations.conf".path}
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

    sops = {
      secrets."github/personalAccessTokens/hydra" = { };
      templates."hydra/github_authorizations.conf" = {
        content = ''
          <github_authorization>
            sebastianrasor = Bearer ${config.sops.placeholder."github/personalAccessTokens/hydra"}
          </github_authorization>
        '';
        owner = "hydra";
        group = "hydra";
        mode = "0440";
      };
    };
  };
}
