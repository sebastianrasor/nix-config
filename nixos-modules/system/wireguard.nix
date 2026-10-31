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
  localIp6 = lib.head (lib.splitString "/" cfg.ipv6Address);
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
  forwardedPorts = lib.concatMap (
    peer:
    let
      peerIp = lib.head (lib.splitString "/" peer.config.sebastianrasor.wireguard.address);
      peerIp6 = lib.head (lib.splitString "/" peer.config.sebastianrasor.wireguard.ipv6Address);
    in
    lib.concatMap (
      fwd:
      let
        destPort = toString (if fwd.destinationPort != null then fwd.destinationPort else fwd.port);
      in
      [
        {
          sourcePort = fwd.port;
          destination = "${peerIp}:${destPort}";
          inherit (fwd) proto;
        }
        {
          sourcePort = fwd.port;
          destination = "[${peerIp6}]:${destPort}";
          inherit (fwd) proto;
        }
      ]
    ) peer.config.sebastianrasor.wireguard.forwardPorts
  ) peers;
in
{
  options.sebastianrasor.wireguard = {
    enable = lib.mkEnableOption "WireGuard";

    address = lib.mkOption {
      type = lib.types.str;
    };

    ipv6Address = lib.mkOption {
      type = lib.types.str;
    };

    domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    forwardPorts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            port = lib.mkOption {
              type = lib.types.port;
            };

            destinationPort = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
            };

            proto = lib.mkOption {
              type = lib.types.enum [
                "tcp"
                "udp"
              ];
              default = "tcp";
            };
          };
        }
      );
      default = [ ];
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
    boot.kernel.sysctl = {
      "net.ipv4.ip_nonlocal_bind" = true;
      "net.ipv6.ip_nonlocal_bind" = true;
    };

    sops.secrets."wireguard/privateKeys/${config.networking.hostName}" =
      lib.mkIf config.sebastianrasor.secrets.enable
        {
          owner = "systemd-network";
        };

    networking = {
      firewall = {
        allowedUDPPorts = lib.mkIf (cfg.listenPort != null) [ cfg.listenPort ];
        trustedInterfaces = [ "wg0" ];
      };

      hosts =
        lib.optionalAttrs (cfg.domains != [ ]) {
          "127.0.0.1" = cfg.domains;
          "::1" = cfg.domains;
        }
        // builtins.listToAttrs (
          lib.concatMap (
            peer:
            let
              peerCfg = peer.config.sebastianrasor.wireguard;
              peerIp = lib.head (lib.splitString "/" peerCfg.address);
              peerIp6 = lib.head (lib.splitString "/" peerCfg.ipv6Address);
            in
            lib.optionals (peerCfg.domains != [ ]) [
              (lib.nameValuePair peerIp peerCfg.domains)
              (lib.nameValuePair peerIp6 peerCfg.domains)
            ]
          ) peers
        );

      nat =
        let
          externalInterface = lib.head (
            builtins.attrNames config.sebastianrasor.systemd-networkd.interfacesRequiredForOnline
          );
        in
        lib.mkIf (cfg.listenPort != null && forwardedPorts != [ ]) {
          enable = true;
          enableIPv6 = true;
          inherit externalInterface;
          forwardPorts = forwardedPorts;
          extraCommands = lib.concatMapStrings (
            peer:
            lib.concatMapStrings (
              fwd:
              lib.optionalString (fwd.destinationPort != null && fwd.destinationPort != fwd.port) ''
                ip46tables -w -t filter -A nixos-filter-forward \
                  -i ${externalInterface} -p ${fwd.proto} \
                  --dport ${toString fwd.destinationPort} -j ACCEPT
              ''
            ) peer.config.sebastianrasor.wireguard.forwardPorts
          ) peers;
        };
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
            peerIp6 = lib.head (lib.splitString "/" peerCfg.ipv6Address);
          in
          {
            PublicKey = peerCfg.publicKey;
            AllowedIPs =
              if peerCfg.listenPort != null then
                [
                  "0.0.0.0/0"
                  "::/0"
                ]
              else
                [
                  "${peerIp}/32"
                  "${peerIp6}/128"
                ];
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
        address = [
          cfg.address
          cfg.ipv6Address
        ];
        networkConfig.ConfigureWithoutCarrier = true;
        linkConfig.RequiredForOnline = "no";
        routingPolicyRules = lib.optionals hasEndpointPeers [
          {
            From = localIp;
            Table = 1000;
          }
          {
            From = localIp6;
            Table = 1000;
          }
        ];
      };
    };
  };
}
