{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.jq.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.jq.enable {
    programs.jq.enable = true;
  };
}
