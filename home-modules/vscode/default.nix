{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.vscode;
in
{
  options.sebastianrasor.vscode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode-with-extensions.override {
        vscode = pkgs.vscodium;
        vscodeExtensions = with pkgs.vscode-extensions; [
          jjk.jjk
          jnoortheen.nix-ide
          mkhl.direnv
          vscodevim.vim
        ];
      };
      mutableExtensionsDir = false;
      profiles.default.userSettings = {
        "terminal.integrated.defaultProfile.linux" = "fish";
        "editor.fontFamily" = "'Atkinson Hyperlegible Mono', monospace";
        "workbench.activityBar.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
        "workbench.tabs.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
        "workbench.statusBar.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
        "workbench.sideBar.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
        "workbench.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
        "workbench.bottomPane.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
        "editor.lineNumbers" = "relative";
        "editor.wordBasedSuggestions" = "off";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.serverSettings" = {
          "nixd" = {
            "nixpkgs" = {
              "expr" = "import (builtins.getFlake (toString ./.)).inputs.nixpkgs { }";
            };
            "formatting" = {
              "command" = [ "nixfmt" ];
            };
            "options" = {
              "nixos" = {
                "expr" = builtins.replaceStrings [ "\\n" "  " ] [ " " "" ] (builtins.readFile ./nixos-options.nix);
              };
              "home_manager" = {
                "expr" =
                  builtins.replaceStrings
                    [ "\\n" "  " "/home/sebastian" "sebastian" ]
                    [ " " "" "\${env:HOME}" "\${env:USER}" ]
                    (builtins.readFile ./home-manager-options.nix);
              };
            };
          };
        };
      };
    };
  };
}
