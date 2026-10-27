_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.core;
in
{
  options.sebastianrasor.core = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    graphical = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      sebastianrasor = { };
    })
    (lib.mkIf cfg.graphical {
      sebastianrasor = {
        zed-editor.enable = true;
      };
    })
  ];
}
