{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.sudo.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.sudo.enable {
    security.sudo.extraConfig = ''
      Defaults:root,%wheel env_keep+=SSH_CONNECTION
    '';
  };
}
