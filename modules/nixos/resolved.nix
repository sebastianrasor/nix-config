{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.resolved.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.resolved.enable {
    services.resolved = {
      enable = true;
      fallbackDns = [
        "8.8.8.8"
        "8.8.4.4"
        "2001:4860:4860::8888"
        "2001:4860:4860::8844"
      ];
      extraConfig = ''
        MulticastDNS=yes
        LLMNR=no
      '';
    };
  };
}
