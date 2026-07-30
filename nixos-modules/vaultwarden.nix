{ constants, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.vaultwarden;
in
{
  options.sebastianrasor.vaultwarden = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = {
        ROCKET_PORT = 8222;
      };
      configurePostgres = true;
      domain = "vaultwarden.ts.${constants.domain}";
      environmentFile = config.sops.templates."vaultwarden.env".path;
    };

    sops = {
      secrets."vaultwarden/adminToken" = { };
      templates."vaultwarden.env".content = ''
        ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/adminToken"}
      '';
    };

    sebastianrasor = {
      persistence.directories = [ "/var/lib/vaultwarden" ];
      reverse-proxy.proxies."vaultwarden" =
        "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };
  };
}
