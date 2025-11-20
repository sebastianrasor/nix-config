{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.sudo-rs.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.sudo-rs.enable {
    security.sudo-rs.enable = true;
  };
}
