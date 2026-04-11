{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.deploy-server;
in
{
  options.sebastianrasor.deploy-server = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.sockets.deploy-server = {
      bindsTo = [ "deploy-server.service" ];
      socketConfig = {
        ListenFIFO = "/run/deploy-server.stdin";
        RemoveOnStop = true;
        FlushPending = true;
      };
    };

    systemd.services.deploy-server = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "deploy-server.socket" ];
      after = [
        "network.target"
        "deploy-server.socket"
      ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.websocat} -s 9999";
        Restart = "always";
        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    sebastianrasor.reverse-proxy.proxies."deploy" = "ws://127.0.0.1:9999";
  };
}
