{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.networkmanager.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.networkmanager.enable {
    environment.persistence."${config.sebastianrasor.persistence.storagePath}".directories =
      lib.mkIf config.sebastianrasor.persistence.enable
        [ "/etc/NetworkManager/system-connections" ];
    networking.networkmanager = {
      enable = true;
      connectionConfig."connection.mdns" = 2;
    };
  };
}
