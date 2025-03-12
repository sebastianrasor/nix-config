{ config, lib, ... }:
{
  options = {
    sebastianrasor.nginx.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.nginx.enable {
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
