{ tailscale-golink, ... }:
{
  config,
  constants,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.tailscale-golink;
in
{
  options.sebastianrasor.tailscale-golink = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  imports = [
    tailscale-golink.nixosModules.default
  ];

  config = lib.mkIf cfg.enable {
    services.golink = {
      enable = true;

      controlUrl = "https://headscale.${constants.domain}";

      tailscaleAuthKeyFile = config.sops.secrets."tailscale/authKey".path;
    };

    sebastianrasor.persistence.directories = [ config.services.golink.dataDir ];

    sops.secrets."tailscale/authKey" = {
      # This doesn't interfere with tailscale at the moment because the current
      # tailscale module runs tailscale as root.
      inherit (config.services.golink) group;
      owner = config.services.golink.user;
    };
  };
}
