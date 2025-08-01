{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.tailscale = {
      enable = lib.mkEnableOption "";
      exitNode = lib.mkEnableOption "";
      authKeyFile = lib.mkOption {
        type = lib.types.str;
        default = null;
      };
    };
  };

  config = lib.mkIf config.sebastianrasor.tailscale.enable {
    sops.secrets.tailscale_key = lib.mkIf config.sebastianrasor.secrets.enable {};
    networking.firewall.trustedInterfaces = ["tailscale0"];
    environment.persistence."${config.sebastianrasor.persistence.storagePath}".files = lib.mkIf config.sebastianrasor.persistence.enable ["/var/lib/tailscale/tailscaled.state"];
    services.tailscale = {
      enable = true;
      authKeyFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.tailscale_key.path;
      extraUpFlags = ["--login-server=https://headscale.${config.sebastianrasor.domain}"];
      extraSetFlags = lib.mkIf config.sebastianrasor.tailscale.exitNode ["--advertise-exit-node"];
      useRoutingFeatures = lib.mkIf config.sebastianrasor.tailscale.exitNode "server";
    };
  };
}
