_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.nix-serve;
in
{
  options.sebastianrasor.nix-serve = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.nix-serve = {
      enable = true;
      secretKeyFile = config.sops.secrets."nix/binaryCacheSecretKey".path;
    };

    sebastianrasor.reverse-proxy.proxies."cache" =
      "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";

    sops.secrets."nix/binaryCacheSecretKey" = { };
  };
}
