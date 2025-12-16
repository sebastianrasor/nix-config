{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.nvf;
in
{
  options.sebastianrasor.nvf = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    programs.nvf = {
      enable = true;
      settings = {
        config.vim = {
          viAlias = false;
          vimAlias = false;

          lsp.servers.nixd.settings.nixd = {
            nixpkgs.expr = ''import (builtins.getFlake ("git+file://" + toString ./.)).inputs.nixpkgs { }'';
            options = {
              nixos.expr = ''let lib = import <nixpkgs/lib>; in (lib.attrsets.mergeAttrsList(builtins.attrValues((builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations))).options'';
              home_manager.expr = ''let lib = import <nixpkgs/lib>; in (lib.attrsets.mergeAttrsList(builtins.attrValues((builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations))).options.home-manager.users.type.getSubOptions []'';
            };
          };

          languages = {
            #enableDAP = true;
            enableExtraDiagnostics = true;
            enableFormat = true;
            enableTreesitter = true;

            bash.enable = true;
            html.enable = true;
            markdown.enable = true;
            nix = {
              enable = true;
              lsp = {
                enable = true;
                servers = [ "nixd" ];
              };
            };
            rust = {
              enable = true;
              extensions.crates-nvim.enable = true;
            };
            ts.enable = true;
          };

          diagnostics.enable = true;

          autocomplete.blink-cmp = {
            enable = true;
            setupOpts = {
              signature.enabled = true;
              sources.providers.buffer.enabled = false;
            };
          };
          autopairs.nvim-autopairs.enable = true;

          notify.nvim-notify.enable = true;

          lsp = {
            formatOnSave = true;
            inlayHints.enable = true;
            lightbulb.enable = true;
            trouble.enable = true;
            otter-nvim.enable = true;
            nvim-docs-view.enable = true;
          };

          visuals = {
            indent-blankline.enable = true;
          };

          theme = {
            enable = true;
            name = "catppuccin";
            style = "mocha";
            transparent = true;
          };

          treesitter = {
            enable = true;
            context.enable = true;
          };
          ui = {
            colorizer.enable = true;
            fastaction.enable = true;
          };

          utility.motion.precognition.enable = true;

          git = {
            enable = true;
          };

          binds = {
            whichKey.enable = true;
          };

          spellcheck.enable = true;

          extraPlugins.hardtime = {
            package = pkgs.vimPlugins.hardtime-nvim;
            setup = "require('hardtime').setup()";
          };

          options = {
            autoindent = false;
            cindent = false;
            ignorecase = true;
            smartcase = true;
            smartindent = false;
            vb = true;

            expandtab = false;
            shiftwidth = 4;
            softtabstop = 4;
            tabstop = 4;
          };
          pluginRC.nix = ''
            vim.api.nvim_create_autocmd("FileType", {
              pattern = "nix",
              callback = function(opts)
                local bo = vim.bo[opts.buf]
                bo.tabstop = 2
                bo.shiftwidth = 2
                bo.softtabstop = 2
                bo.expandtab = true
              end
            })
          '';
        };
      };
    };
    home.sessionVariables.EDITOR = "nvim";
    programs.fish.shellAbbrs = lib.mkIf config.sebastianrasor.fish.enable {
      vim = "nvim";
    };
    home.shellAliases = lib.mkIf (!config.sebastianrasor.fish.enable) {
      vim = "nvim";
    };
  };
}
