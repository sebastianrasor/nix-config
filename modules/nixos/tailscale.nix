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
    sops.secrets.tailscale_key = lib.mkIf config.sebastianrasor.secrets.enable {};
    services.tailscale = {
      enable = true;
      authKeyFile = lib.mkIf config.sebastianrasor.secrets.enable config.sops.secrets.tailscale_key.path;
      extraUpFlags = ["--login-server=https://headscale.rasor.us"];
    };
  };
}
