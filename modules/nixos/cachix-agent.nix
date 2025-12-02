{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.cachix-agent;
  secretsEnabled = config.sebastianrasor.secrets.enable;
in
{
  options.sebastianrasor.cachix-agent = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    services.cachix-agent = {
      enable = true;
      credentialsFile = lib.mkIf secretsEnabled config.sops.secrets.cachix-agent-token.path;
    };
    sops.secrets.cachix-agent-token = lib.mkIf secretsEnabled { };
  };
}
