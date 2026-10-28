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
    enable = lib.mkEnableOption "Harmonia binary cache";
  };

  config = lib.mkIf cfg.enable {
    services.harmonia.cache = {
      enable = true;
      settings.bind = "127.0.0.1:5000";
      signKeyPaths = [ config.sops.secrets."nix/binaryCacheSecretKey".path ];
    };

    sebastianrasor.reverse-proxy.proxies."cache" =
      "http://${config.services.harmonia.cache.settings.bind}";

    sops.secrets."nix/binaryCacheSecretKey" = { };
  };
}
