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
      hydraURL = "hydra.${config.sebastianrasor.reverse-proxy.baseDomainName}";
      listenHost = "localhost";
      notificationSender = "hydra@${constants.domain}";
      useSubstitutes = true;
      extraConfig = ''
        <dynamicruncommand>
          enable = 1
        </dynamicruncommand>
      '';
    };

    sebastianrasor.reverse-proxy.proxies."hydra" =
      "http://${config.services.hydra.listenHost}:${toString config.services.hydra.port}";
  };
}
