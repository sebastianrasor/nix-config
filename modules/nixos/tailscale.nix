{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.tailscale;
in
{
  options.sebastianrasor.tailscale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    exitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    authKeyFile = lib.mkOption {
      type = lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.tailscale_key = lib.mkIf config.sebastianrasor.secrets.enable { };
    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
    services.tailscale = {
      enable = true;
      authKeyFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.tailscale_key.path;
      extraDaemonFlags = [ "--encrypt-state=false" ];
      extraUpFlags = [ "--login-server=https://headscale.${config.sebastianrasor.domain}" ];
      extraSetFlags = lib.mkIf config.sebastianrasor.tailscale.exitNode [ "--advertise-exit-node" ];
      useRoutingFeatures = lib.mkIf config.sebastianrasor.tailscale.exitNode "server";
    };
    sebastianrasor.persistence.files = [ "/var/lib/tailscale/tailscaled.state" ];
  };
}
