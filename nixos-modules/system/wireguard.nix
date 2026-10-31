{
  constants,
  self,
  ...
}:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.wireguard;
  localIp = lib.head (lib.splitString "/" cfg.address);
  peers = lib.pipe self.nixosConfigurations [
    builtins.attrValues
    (lib.filter (
      host:
      host.config.networking.hostName != config.networking.hostName
      && host.config.sebastianrasor.wireguard.enable
    ))
  ];
  hasEndpointPeers = builtins.any (
    peer: peer.config.sebastianrasor.wireguard.listenPort != null
  ) peers;
in
{
  options.sebastianrasor.wireguard = {
    enable = lib.mkEnableOption "WireGuard";

    address = lib.mkOption {
      type = lib.types.str;
    };

    listenPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
    };

    publicKey = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."wireguard/privateKeys/${config.networking.hostName}" =
      lib.mkIf config.sebastianrasor.secrets.enable
        {
          owner = "systemd-network";
        };

    networking.firewall = {
      allowedUDPPorts = lib.mkIf (cfg.listenPort != null) [ cfg.listenPort ];
      trustedInterfaces = [ "wg0" ];
    };

    systemd.network = {
      netdevs."50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
        wireguardConfig =
          lib.optionalAttrs (cfg.listenPort != null) {
            ListenPort = cfg.listenPort;
          }
          // lib.optionalAttrs config.sebastianrasor.secrets.enable {
            PrivateKeyFile = config.sops.secrets."wireguard/privateKeys/${config.networking.hostName}".path;
          };
        wireguardPeers = map (
          peer:
          let
            peerCfg = peer.config.sebastianrasor.wireguard;
            peerIp = lib.head (lib.splitString "/" peerCfg.address);
          in
          {
            PublicKey = peerCfg.publicKey;
            AllowedIPs = if peerCfg.listenPort != null then [ "0.0.0.0/0" ] else [ "${peerIp}/32" ];
          }
          // lib.optionalAttrs (peerCfg.listenPort != null) {
            Endpoint = "${peer.config.networking.hostName}.${constants.domain}:${toString peerCfg.listenPort}";
            PersistentKeepalive = 25;
            RouteTable = 1000;
          }
        ) peers;
      };

      networks."50-wg0" = {
        matchConfig.Name = "wg0";
        address = [ cfg.address ];
        networkConfig.ConfigureWithoutCarrier = true;
        linkConfig.RequiredForOnline = "no";
        routingPolicyRules = lib.optionals hasEndpointPeers [
          {
            From = localIp;
            Table = 1000;
          }
        ];
      };
    };
  };
}
