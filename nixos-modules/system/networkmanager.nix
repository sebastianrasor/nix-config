_:
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
    enable = lib.mkEnableOption "NetworkManager";
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager = {
      enable = true;
      connectionConfig."connection.mdns" = 2;
      wifi.backend = "iwd";
    };

    users.users.sebastian.extraGroups = [ "networkmanager" ];

    sebastianrasor.persistence.directories = [ "/etc/NetworkManager/system-connections" ];
  };
}
