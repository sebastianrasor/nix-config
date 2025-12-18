{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.eza;
in
{
  options.sebastianrasor.eza = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.eza = {
      enable = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };

    home.shellAliases = {
      ls = "eza";
      tree = "eza --tree";
    };
  };
}
