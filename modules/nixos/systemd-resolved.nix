{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.systemd-resolved;
in
{
  options.sebastianrasor.systemd-resolved = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
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
