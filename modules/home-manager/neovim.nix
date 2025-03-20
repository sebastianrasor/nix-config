{
  config,
  lib,
  pkgs,
  outputs,
  ...
}: {
  options = {
    sebastianrasor.neovim.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.neovim.enable {
    home.packages = [outputs.packages.${pkgs.system}.neovim-sebastianrasor];
    programs.fish.shellAbbrs = lib.mkIf config.sebastianrasor.fish.enable {
      vim = "nvim";
    };
    home.shellAliases = lib.mkIf (!config.sebastianrasor.fish.enable) {
      vim = "nvim";
      _vim = "${lib.getExe pkgs.vim}";
    };
  };
}
