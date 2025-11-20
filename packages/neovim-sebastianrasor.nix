{
  inputs,
  pkgs,
  ...
}:
let
  configuration = {
    config.vim = {
      package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.system}.neovim;
      viAlias = false;
      vimAlias = false;

      languages = {
        enableDAP = true;
        enableExtraDiagnostics = true;
        enableFormat = true;
        enableTreesitter = true;

        bash.enable = true;
        html.enable = true;
        markdown.enable = true;
        nix = {
          enable = true;
          format = {
            type = "nixfmt";
            enable = true;
          };
          lsp = {
            enable = true;
            package = [ "nixd" ];
            server = "nixd";
            options = {
              nixos.expr = ''let lib = import <nixpkgs/lib>; in (lib.attrsets.mergeAttrsList(builtins.attrValues((builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations))).options'';
              home_manager.expr = ''let lib = import <nixpkgs/lib>; in (lib.attrsets.mergeAttrsList(builtins.attrValues((builtins.getFlake ("git+file://" + toString ./.)).homeConfigurations))).options'';
            };
          };
        };
        rust = {
          enable = true;
          crates.enable = true;
          lsp = {
            enable = true;
            package = [ "rust-analyzer" ];
            opts = ''
              ['rust-analyzer'] = {
                check = {
                  command = "clippy",
                },
              },
            '';
          };
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
in
(inputs.nvf.lib.neovimConfiguration {
  inherit pkgs;
  modules = [ configuration ];
}).neovim
