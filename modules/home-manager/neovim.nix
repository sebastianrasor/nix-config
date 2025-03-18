{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  options = {
    sebastianrasor.neovim.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.neovim.enable {
    home.packages = [self.packages.${pkgs.system}.neovim-sebastianrasor];
    programs.fish.shellAbbrs = lib.mkIf config.sebastianrasor.fish.enable {
      vim = "nvim";
    };
    home.shellAliases = lib.mkIf (!config.sebastianrasor.fish.enable) {
      vim = "nvim";
      _vim = "${lib.getExe pkgs.vim}";
    };
  };
}
