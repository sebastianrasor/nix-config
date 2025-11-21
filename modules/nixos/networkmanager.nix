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
    networking.networkmanager = {
      enable = true;
      connectionConfig."connection.mdns" = 2;
    };
    sebastianrasor.persistence.directories = [ "/etc/NetworkManager/system-connections" ];
  };
}
