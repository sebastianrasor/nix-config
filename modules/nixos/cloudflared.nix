{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.cloudflared.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.cloudflared.enable {
    # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
    boot.kernel.sysctl."net.core.rmem_max" = 7500000;
    services.cloudflared = {
      enable = true;
      certificateFile = "/nix/persist/cloudflare/cert.pem";
      tunnels = {
        "593a3d19-91e8-4b8c-8355-e9646f30985f" = {
          credentialsFile = "/nix/persist/cloudflare/593a3d19-91e8-4b8c-8355-e9646f30985f.json";
          default = "http_status:404";
        };
      };
    };
  };
}
