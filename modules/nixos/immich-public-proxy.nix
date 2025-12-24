{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.immich-public-proxy;
in
{
  options.sebastianrasor.immich-public-proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.immich-public-proxy = {
      enable = true;
      port = 3001;
      immichUrl = "https://immich.ts.${config.sebastianrasor.domain}";
    };

    sebastianrasor.reverse-proxy.proxies."immich" =
      "http://127.0.0.1:${toString config.services.immich-public-proxy.port}";
  };
}
