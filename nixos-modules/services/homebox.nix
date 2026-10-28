_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.homebox;
in
{
  options.sebastianrasor.homebox = {
    enable = lib.mkEnableOption "Homebox";
  };

  config = lib.mkIf cfg.enable {
    services.homebox = {
      enable = true;
      database.createLocally = true;
    };

    sebastianrasor.reverse-proxy.proxies."homebox" = "http://127.0.0.1:7745";
  };
}
