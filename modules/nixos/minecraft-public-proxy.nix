{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.minecraft-public-proxy.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.minecraft-public-proxy.enable {
    networking.firewall.allowedTCPPorts = [ 25565 ];
    networking.firewall.allowedUDPPorts = [ 24454 ];
    services.nginx.streamConfig = ''
      server {
        listen 25565;
        resolver 100.100.100.100;
        set $carbon_mc "carbon.ts.${config.sebastianrasor.domain}:25565";
        proxy_pass $carbon_mc;
      }
      server {
        listen 24454 udp;
        resolver 100.100.100.100;
        set $carbon_svc "carbon.ts.${config.sebastianrasor.domain}:24454";
        proxy_pass $carbon_svc;
        proxy_responses 0;
      }
    '';
  };
}
