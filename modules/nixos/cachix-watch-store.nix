{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.cachix-watch-store;
  secretsEnabled = config.sebastianrasor.secrets.enable;
in
{
  options.sebastianrasor.cachix-watch-store = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    cacheName = lib.mkOption {
      type = lib.types.str;
      default = "sebastianrasor";
    };

    cachixTokenFile = lib.mkOption {
      type = lib.types.path;
      default = if secretsEnabled then config.sops.secrets.cachix-auth-token.path else null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.cachix-watch-store = {
      enable = true;
      inherit (cfg) cacheName cachixTokenFile;
    };
    sops.secrets.cachix-auth-token = lib.mkIf secretsEnabled { };
  };
}
