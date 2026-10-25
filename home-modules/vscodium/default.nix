_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.vscodium;
in
{
  options.sebastianrasor.vscodium = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscodium = {
      enable = true;
      package =
        (pkgs.vscodium.fhsWithPackages (
          ps: with ps; [
            djlint
            (pkgs.runCommand "fhs-ca-certificates" { } ''
              install -Dm644 ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-certificates.crt
              install -Dm644 ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/cert.pem
              install -Dm644 ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/pki/tls/certs/ca-bundle.crt
            '')
            stdenv.cc.cc.lib
            zlib
          ]
        )).override
          {
            extraArgs = "--no-sandbox --disable-gpu-sandbox";
          };
      mutableExtensionsDir = false;
      profiles.default = {
        extensions =
          with pkgs.vscode-extensions;
          [
            jjk.jjk
            jnoortheen.nix-ide
            mkhl.direnv
            rust-lang.rust-analyzer
            vscodevim.vim
          ]
          ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "djlint";
              publisher = "monosans";
              version = "2026.10.1";
              hash = "sha256-BbNMtS9GZp2iuH+uICltm1jbz2hADmoYGXbTPvxvPiU=";
            }
            {
              name = "google-antigravity";
              publisher = "Google";
              version = "1.9.0";
              hash = "sha256-OPLYwhG3alJMvhbSJZ9U/e6IzIrfI7vSVvNxFq9mRVg=";
            }
          ];
        userSettings = {
          "[django-html][jinja][jinja-html][jinja2][html-hubl][hubl-html][twig][html-nunjucks][njk][nunjucks][handlebars][hbs][spacebars][liquid][jekyll][go-template][go-tmpl][gotemplate][GoTemplate][gohtml][GoHTML][gotmpl][hugo-html][mustache][htmlmustache][tera][askama-html][html]" =
            {
              "editor.defaultFormatter" = "monosans.djlint";
            };
          "djlint.useVenv" = false;
          "djlint.executablePath" = lib.getExe pkgs.djlint;
          "terminal.integrated.defaultProfile.linux" = "fish";
          "editor.fontFamily" = "'Atkinson Hyperlegible Mono', monospace";
          "workbench.activityBar.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
          "workbench.tabs.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
          "workbench.statusBar.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
          "workbench.sideBar.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
          "workbench.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
          "workbench.bottomPane.experimental.fontFamily" = "'Atkinson Hyperlegible Next'";
          "files.insertFinalNewline" = true;
          "editor.formatOnSave" = true;
          "editor.lineNumbers" = "relative";
          "editor.inlayHints.enabled" = "offUnlessPressed";
          "editor.wordBasedSuggestions" = "off";
          "editor.rulers" = [ 80 ];
          "[java][rust][nix]" = {
            "editor.rulers" = [ 100 ];
          };
          "[git-commit]" = {
            "editor.rulers" = [
              50
              72
            ];
          };
          "editor.minimap.enabled" = false;
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
  };
}
