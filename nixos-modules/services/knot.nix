{
  constants,
  tangled,
  ...
}:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.knot;
  inherit (config.services.tangled.knot-rs) stateDir;
in
{
  options.sebastianrasor.knot = {
    enable = lib.mkEnableOption "Tangled Knot";
  };

  imports = [
    tangled.nixosModules.knot-rs
  ];

  config = lib.mkIf cfg.enable {
    services.tangled.knot-rs = {
      enable = true;
      environmentFile = config.sops.templates."knot.env".path;
      settings = {
        server = {
          hostname = "knot.${constants.domain}";
          admins = [ "did:web:sebastianrasor.com" ];
        };
        atproto.plc_directory = "https://plc.directory";
        contact.email = "knot@${constants.domain}";
        http.block_private_addresses = false;
        lfs.store_path = "${stateDir}/lfs";
        xrpc = {
          trusted_proxy_header = "x-forwarded-for";
          trusted_proxies = [
            "127.0.0.1"
            "::1"
          ];
        };
      };
    };

    systemd.services.knot-rs = {
      after = [
        "nginx.service"
        "tranquil-pds.service"
      ];
      unitConfig.RequiresMountsFor = [ stateDir ];
      serviceConfig = {
        StateDirectory = [
          "knot"
          "knot/repos"
          "knot/lfs"
        ];
        StateDirectoryMode = "0750";
      };
    };

    programs.ssh.extraConfig = ''
      Host knot.${constants.domain}
        Port 2222
    '';

    sops = {
      secrets."knot/masterKey" = { };
      templates."knot.env".content = ''
        KNOT_MASTER_KEY=${config.sops.placeholder."knot/masterKey"}
      '';
    };

    sebastianrasor = {
      persistence.directories = [
        {
          directory = stateDir;
          inherit (config.services.tangled.knot-rs) user group;
          mode = "0750";
        }
      ];

      reverse-proxy.proxies."knot.${constants.domain}" = {
        public = true;
        target = "http://${config.services.tangled.knot-rs.settings.server.listen_addr}";
      };

      wireguard.forwardPorts = [
        {
          port = 22;
          destinationPort = 2222;
          proto = "tcp";
        }
      ];
    };
  };
}
