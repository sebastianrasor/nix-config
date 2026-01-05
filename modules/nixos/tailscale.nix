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

    authKeyFile = lib.mkOption {
      type = lib.types.str;
      default = null;
    };

    exitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://headscale.${config.sebastianrasor.domain}";
    };

    operator = lib.mkOption {
      type = lib.types.str;
      default = "sebastian";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.tailscale_key = lib.mkIf config.sebastianrasor.secrets.enable { };
    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
    services.tailscale = {
      enable = true;
      authKeyFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.tailscale_key.path;
      extraDaemonFlags = [ "--encrypt-state=false" ];
      extraUpFlags = [ "--login-server=${cfg.loginServer}" ];
      extraSetFlags = [
        "--operator=${cfg.operator}"
      ]
      ++ lib.optionals cfg.exitNode [ "--advertise-exit-node" ];
      useRoutingFeatures = if cfg.exitNode then "both" else "client";
    };
    sebastianrasor.persistence.files = [ "/var/lib/tailscale/tailscaled.state" ];
  };
}
