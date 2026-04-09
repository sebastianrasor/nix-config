{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.networkmanager;
in
{
  options.sebastianrasor.networkmanager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager = {
      enable = true;
      connectionConfig."connection.mdns" = 2;
      wifi.backend = "iwd";
    };

    sebastianrasor.persistence.directories = [ "/etc/NetworkManager/system-connections" ];
  };
}
