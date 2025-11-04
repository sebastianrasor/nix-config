{
  config,
  lib,
  pkgs,
  outputs,
  ...
}: {
  options = {
    sebastianrasor.neovim = {
      enable = lib.mkEnableOption "";
      package = lib.mkOption {
        default = outputs.packages.${pkgs.stdenv.hostPlatform.system}.neovim-sebastianrasor;
        type = lib.types.package;
      };
    };
  };

  config = lib.mkIf config.sebastianrasor.neovim.enable {
    home.packages = [config.sebastianrasor.neovim.package];
    home.sessionVariables.EDITOR = "nvim";
    programs.fish.shellAbbrs = lib.mkIf config.sebastianrasor.fish.enable {
      vim = "nvim";
    };
    home.shellAliases = lib.mkIf (!config.sebastianrasor.fish.enable) {
      vim = "nvim";
    };
  };
}
