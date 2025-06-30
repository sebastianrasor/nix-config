{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.tailscale = {
      enable = lib.mkEnableOption "";
      authKeyFile = lib.mkOption {
        type = lib.types.str;
        default = null;
      };
    };
  };

  config = lib.mkIf config.sebastianrasor.tailscale.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = config.sebastianrasor.tailscale.authKeyFile;
      extraUpFlags = ["--login-server=https://headscale.rasor.us"];
    };
  };
}
