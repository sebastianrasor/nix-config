{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.authentik-public-proxy;
in
{
  options.sebastianrasor.authentik-public-proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    sebastianrasor.reverse-proxy.proxies."authentik" =
      "https://authentik.ts.${config.sebastianrasor.domain}";
  };
}
