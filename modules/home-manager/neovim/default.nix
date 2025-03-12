{
  config,
  lib,
  neovim-nightly-overlay,
  pkgs,
  ...
}:
{
  options = {
    sebastianrasor.neovim.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.neovim.enable {
    programs.neovim = {
      enable = true;
      extraLuaConfig = lib.fileContents ./init.lua;
      package = neovim-nightly-overlay.packages.${pkgs.system}.default;
      plugins = with pkgs.vimPlugins; [
        hardtime-nvim
        nui-nvim
        plenary-nvim
      ];
    };
    programs.fish.shellAbbrs = lib.mkIf config.sebastianrasor.fish.enable {
      vim = "nvim";
    };
    home.shellAliases = lib.mkIf (!config.sebastianrasor.fish.enable) {
      vim = "nvim";
      _vim = "${lib.getExe pkgs.vim}";
    };
    xdg.desktopEntries.nvim = {
      name = "Neovim";
      noDisplay = true;
    };
  };
}
