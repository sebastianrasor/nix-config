{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.actual;
in
{
  options.sebastianrasor.actual = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.actual = {
      enable = true;
      settings = {
        loginMethod = "openid";
        allowedLoginMethods = [ "openid" ];
      };
      # https://github.com/NixOS/nixpkgs/issues/475898
      # https://nixpkgs-tracker.ocfox.me/?pr=475880
      package =
        let
          nodejs = pkgs.nodejs_22;
          yarn-berry = pkgs.yarn-berry_4.override { inherit nodejs; };
        in
        pkgs.actual-server.override {
          yarn-berry_4 = yarn-berry.overrideAttrs (old: {
            passthru = old.passthru // {
              yarnBerryConfigHook = old.passthru.yarnBerryConfigHook.override { inherit nodejs; };
            };
          });
        };
    };

    sebastianrasor.reverse-proxy.proxies."actual" =
      "http://127.0.0.1:${toString config.services.actual.settings.port}";

    # I really can't be bothered to try to figure out the best way to persist
    # the individual StateDirectory of a service with DynamicUser enabled.
    # Just going to add /var/lib/private as a persisted directory in core.
    #sebastianrasor.persistence.directories = [config.services.actual.settings.dataDir];

    #sebastianrasor.unas.mounts."Actual" = "/media/actual";
  };
}
