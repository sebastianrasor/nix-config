{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.eza.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.eza.enable {
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
