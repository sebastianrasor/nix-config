{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.checkemail.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.checkemail.enable {
    sops.secrets.checkemail-env = lib.mkIf config.sebastianrasor.secrets.enable {};
    systemd.services.checkemail = {
      description = "checkemail";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        EnvironmentFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.checkemail-env.path;
        ExecStart = "${lib.getExe' inputs.checkemail.packages.${pkgs.system}.default "checkemail"}";
        Restart = "always";
      };
    };
    services.nginx.virtualHosts."checkemail.${config.sebastianrasor.domain}" = {
      forceSSL = lib.mkIf config.sebastianrasor.acme.enable true;
      enableACME = lib.mkIf config.sebastianrasor.acme.enable true;
      acmeRoot = lib.mkIf config.sebastianrasor.acme.enable null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
        extraConfig = "proxy_ssl_server_name on;" + "proxy_pass_header Authorization;";
      };
    };
  };
}
