_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.harmonia;
in
{
  options.sebastianrasor.harmonia = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.harmonia.cache = {
      enable = true;
      signKeyPaths = [ config.sops.secrets."nix/binaryCacheSecretKey".path ];
    };

    sebastianrasor.reverse-proxy.proxies."cache" =
      "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";

    sops.secrets."nix/binaryCacheSecretKey" = { };
  };
}
