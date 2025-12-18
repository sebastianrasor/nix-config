{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.nginx;
in
{
  options.sebastianrasor.nginx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
  };
}
