{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.browserpass;
in
{
  options.sebastianrasor.browserpass = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.browserpass.enable = true;
  };
}
