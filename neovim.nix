{pkgs, ...}: {
  config.vim = {
    languages = {
      enableLSP = true;
      enableFormat = true;
      enableTreesitter = true;

      bash.enable = true;
      html.enable = true;
      markdown.enable = true;
      nix = {
        enable = true;
        format.type = "alejandra";
        lsp = {
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
      };
      ts.enable = true;
    };

    autocomplete.nvim-cmp.enable = true;
    autopairs.nvim-autopairs.enable = true;

    notify.nvim-notify.enable = true;

    lsp = {
      formatOnSave = true;
      lightbulb.enable = true;
      trouble.enable = true;
      lspSignature.enable = true;
      otter-nvim.enable = true;
      lsplines.enable = true;
      nvim-docs-view.enable = true;
    };

    visuals = {
      indent-blankline.enable = true;
    };

    treesitter = {
      enable = true;
      context.enable = true;
    };
    ui = {
      fastaction.enable = true;
    };

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
      termguicolors = false;
      vb = true;

      expandtab = false;
      shiftwidth = 4;
      softtabstop = 4;
      tabstop = 4;
    };
  };
}
