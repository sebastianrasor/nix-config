_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.open-webui;
in
{
  options.sebastianrasor.open-webui = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      environment = {
        OLLAMA_API_BASE_URL = "http://${config.services.ollama.host}:${toString config.services.ollama.port}";
        WEBUI_AUTH = "False";
      };
    };

    sebastianrasor.reverse-proxy.proxies."open-webui" =
      "http://${config.services.open-webui.host}:${toString config.services.open-webui.port}";

    #sebastianrasor.persistence.directories = [
    #  config.services.open-webui.stateDir
    #];
  };
}
