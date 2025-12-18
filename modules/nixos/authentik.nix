{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.authentik;
in
{
  options.sebastianrasor.authentik = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.authentik-env = lib.mkIf config.sebastianrasor.secrets.enable { };
    services.authentik = {
      enable = true;
      environmentFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.authentik-env.path;
      nginx = {
        enable = true;
        enableACME = true;
        host = "authentik.ts.${config.sebastianrasor.domain}";
      };
      settings = {
        disable_startup_analytics = true;
        avatars = "initials";
      };
    };
    services.nginx.virtualHosts.${config.services.authentik.nginx.host} = {
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      serverAliases = [ "authentik.${config.sebastianrasor.domain}" ];
    };
  };
}
