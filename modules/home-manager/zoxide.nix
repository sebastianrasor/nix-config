{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.zoxide;
in
{
  options.sebastianrasor.zoxide = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zoxide.enable = true;

    sebastianrasor.persistence.directories = [ "${config.xdg.dataHome}/zoxide" ];
  };
}
