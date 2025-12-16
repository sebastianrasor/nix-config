{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.systemd-networkd;
in
{
  options.sebastianrasor.systemd-networkd = {
    enable = lib.mkEnableOption "";

    interfacesRequiredForOnline = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;
      networks =
        let
          sharedConfig = {
            networkConfig.DHCP = "yes";
          };
        in
        {
          "99-ether" = sharedConfig // {
            linkConfig.RequiredForOnline = "no";
            matchConfig.Type = "ether";
          };
        }
        // lib.mapAttrs' (
          name: value:
          lib.nameValuePair "10-${name}-required-for-online" (
            sharedConfig
            // {
              linkConfig.RequiredForOnline = value;
              matchConfig.Name = name;
            }
          )
        ) cfg.interfacesRequiredForOnline;
    };
    networking.useDHCP = false;
  };
}
