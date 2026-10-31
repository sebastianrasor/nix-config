{ authentik-nix, constants, ... }:
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
    enable = lib.mkEnableOption "authentik";
  };

  imports = [
    authentik-nix.nixosModules.default
  ];

  config = lib.mkIf cfg.enable {
    services.authentik = {
      enable = true;
      environmentFile = config.sops.templates."authentik.env".path;
      nginx = {
        enable = true;
        host = "authentik.${constants.domain}";
      };
      settings = {
        disable_startup_analytics = true;
        avatars = "initials";
      };
    };

    sebastianrasor.reverse-proxy.proxies."authentik.${constants.domain}" = {
      public = true;
    };

    sops = {
      secrets."authentik/secretKey" = { };
      templates."authentik.env".content = ''
        AUTHENTIK_SECRET_KEY=${config.sops.placeholder."authentik/secretKey"}
      '';
    };
  };
}
