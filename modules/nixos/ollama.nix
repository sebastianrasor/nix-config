{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.ollama;
in
{
  options.sebastianrasor.ollama = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-vulkan;
    };

    sebastianrasor.reverse-proxy.proxies."ollama" = "http://${config.services.ollama.host}:${toString config.services.ollama.port}";

    #sebastianrasor.persistence.directories = [
    #  config.services.ollama.home
    #];
  };
}
