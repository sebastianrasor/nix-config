{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.authentik.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.authentik.enable {
    sops.secrets.authentik-env = lib.mkIf config.sebastianrasor.secrets.enable {};
    services.authentik = {
      enable = true;
      environmentFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.authentik-env.path;
      nginx = {
        enable = true;
        enableACME = true;
        host = "authentik.${config.sebastianrasor.domain}";
      };
      settings = {
        disable_startup_analytics = true;
        avatars = "initials";
      };
    };
    services.nginx.virtualHosts.${config.services.authentik.nginx.host}.acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
  };
}
