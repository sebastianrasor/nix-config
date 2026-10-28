{ constants, ... }:
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
    enable = lib.mkEnableOption "Tailscale";

    exitNode = lib.mkEnableOption "Tailscale exit node";

    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://headscale.${constants.domain}";
    };

    operator = lib.mkOption {
      type = lib.types.str;
      default = "sebastian";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."tailscale/authKey" = { };
    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale/authKey".path;
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
