{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.starship.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.starship.enable {
    programs.starship = {
      enable = true;
      enableTransience = true;
      settings = {
        nix_shell.heuristic = true;
        shlvl.disabled = false;
      };
    };
  };
}
