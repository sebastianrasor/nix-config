{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.tailscale-golink;
  secretsEnabled = config.sebastianrasor.secrets.enable;
in
{
  options.sebastianrasor.tailscale-golink = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    services.golink = {
      enable = true;

      controlUrl = "https://headscale.${config.sebastianrasor.domain}";

      tailscaleAuthKeyFile = lib.mkIf secretsEnabled config.sops.secrets.tailscale_key.path;
    };

    sebastianrasor.persistence.directories = [ config.services.golink.dataDir ];

    sops.secrets.tailscale_key = lib.mkIf secretsEnabled {
      # This doesn't interfere with tailscale at the moment because the current
      # tailscale module runs tailscale as root.
      owner = config.services.golink.user;
      group = config.services.golink.group;
    };
  };
}
