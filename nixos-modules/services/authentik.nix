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
        host = "authentik.ts.${constants.domain}";
      };
      settings = {
        disable_startup_analytics = true;
        avatars = "initials";
      };
    };

    networking.hosts."127.0.0.1" = [ "authentik.${constants.domain}" ];

    sebastianrasor.reverse-proxy.proxies."authentik" = {
      aliases = [ "authentik.${constants.domain}" ];
    };

    sops = {
      secrets."authentik/secretKey" = { };
      templates."authentik.env".content = ''
        AUTHENTIK_SECRET_KEY=${config.sops.placeholder."authentik/secretKey"}
      '';
    };
  };
}
