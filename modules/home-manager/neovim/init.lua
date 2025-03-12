require("hardtime").setup()

vim.opt.termguicolors = false
vim.opt.number = true
vim.opt.relativenumber = true

function _G.lsp_status()
	local lspStatus = vim.lsp.status()
	if #lspStatus > 0 then
		return lspStatus
	else
		return [[%<%f %h%w%m%r%=%-14.(%l,%c%V%) %P]]
	end
end

if vim.fn.executable('rust-analyzer') == 1 then
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'rust',
    callback = function(args)
      vim.lsp.start({
        name = 'rust-analyzer',
        cmd = {'rust-analyzer'},
        root_dir = vim.fs.root(args.buf, {'Cargo.toml'}),
      })
			vim.opt.statusline = [[%!v:lua.lsp_status()]]
    end,
  })
end

if vim.fn.executable('nixd') == 1 then
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'nix',
    callback = function(args)
      vim.lsp.start({
        name = 'nixd',
        cmd = {'nixd'},
        --root_dir = vim.fs.root(args.buf, {'flake.nix'}),
      })
			vim.opt.statusline = [[%!v:lua.lsp_status()]]
    end,
  })
elseif vim.fn.executable('nil') == 1 then
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'nix',
    callback = function(args)
      vim.lsp.start({
        name = 'nil',
        cmd = {'nil'},
        root_dir = vim.fs.root(args.buf, {'flake.nix'}),
      })
			vim.opt.statusline = [[%!v:lua.lsp_status()]]
    end,
  })
end

--
--vim.api.nvim_create_autocmd('LspAttach', {
--  desc = 'Enable vim.lsp.completion',
--  callback = function(event)
--    local client_id = vim.tbl_get(event, 'data', 'client_id')
--    if client_id == nil then
--      return
--    end
--    local client = vim.lsp.get_client_by_id(client_id)
--
--    vim.lsp.completion.enable(true, client_id, event.buf, {autotrigger = true})
--    vim.keymap.set({'i'}, '<C-Space>', function ()
--      vim.lsp.completion.trigger()
--    end, {buffer = event.buf})
--
--
--  end
--})

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Enable vim.lsp.completion',
  callback = function(event)
    local client_id = vim.tbl_get(event, 'data', 'client_id')
    if client_id == nil then
      return
    end
    local client = vim.lsp.get_client_by_id(client_id)
    ---Utility for keymap creation.
    ---@param lhs string
    ---@param rhs string|function
    ---@param opts string|table
    ---@param mode? string|string[]
    local function keymap(lhs, rhs, opts, mode)
        opts = type(opts) == 'string' and { desc = opts }
            or vim.tbl_extend('error', opts --[[@as table]], { buffer = event.buf })
        mode = mode or 'n'
        vim.keymap.set(mode, lhs, rhs, opts)
    end
    
    ---For replacing certain <C-x>... keymaps.
    ---@param keys string
    local function feedkeys(keys)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'n', true)
    end
    
    ---Is the completion menu open?
    local function pumvisible()
        return tonumber(vim.fn.pumvisible()) ~= 0
    end
    
    -- Enable completion and configure keybindings.
    vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    
    -- Use enter to accept completions.
    keymap('<cr>', function()
        return pumvisible() and '<C-y>' or '<cr>'
    end, { expr = true }, 'i')
    
    -- Use slash to dismiss the completion menu.
    keymap('/', function()
        return pumvisible() and '<C-e>' or '/'
    end, { expr = true }, 'i')
    
    -- Use <C-n> to navigate to the next completion or:
    -- - Trigger LSP completion.
    -- - If there's no one, fallback to vanilla omnifunc.
    keymap('<C-n>', function()
        if pumvisible() then
            feedkeys '<C-n>'
        else
            if next(vim.lsp.get_clients { bufnr = 0 }) then
                vim.lsp.completion.trigger()
            else
                if vim.bo.omnifunc == '' then
                    feedkeys '<C-x><C-n>'
                else
                    feedkeys '<C-x><C-o>'
                end
            end
        end
    end, 'Trigger/select next completion', 'i')
    
    -- Buffer completions.
    keymap('<C-u>', '<C-x><C-n>', { desc = 'Buffer completions' }, 'i')
    
    -- Use <Tab> to accept a Copilot suggestion, navigate between snippet tabstops,
    -- or select the next completion.
    -- Do something similar with <S-Tab>.
    keymap('<Tab>', function()
        if pumvisible() then
            feedkeys '<C-n>'
        elseif vim.snippet.active { direction = 1 } then
            vim.snippet.jump(1)
        else
            feedkeys '<Tab>'
        end
    end, {}, { 'i', 's' })
    keymap('<S-Tab>', function()
        if pumvisible() then
            feedkeys '<C-p>'
        elseif vim.snippet.active { direction = -1 } then
            vim.snippet.jump(-1)
        else
            feedkeys '<S-Tab>'
        end
    end, {}, { 'i', 's' })

    vim.opt.completeopt = {'menu','noselect', 'fuzzy'}
    vim.o.foldenable = true
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldmethod = "expr"
    vim.o.foldexpr = "v:lua.vim.lsp.foldexpr()"
    
    -- Inside a snippet, use backspace to remove the placeholder.
    keymap('<BS>', '<C-o>s', {}, 's')

		keymap('[g', vim.diagnostic.goto_prev, {})
		keymap(']g', vim.diagnostic.goto_next, {})
		keymap('gd', vim.lsp.buf.definition, {})
		keymap('gD', vim.lsp.buf.declaration, {})
		keymap('gr', vim.lsp.buf.references, {})
		keymap('gt', vim.lsp.buf.type_definition, {})
		keymap('gi', vim.lsp.buf.implementation, {})
		keymap('K', vim.lsp.buf.hover, {})
		keymap('<C-k>', vim.lsp.buf.signature_help, {})
		keymap('<Leader>rn', vim.lsp.buf.rename, {})
		keymap('<Leader>ca', vim.lsp.buf.code_action, {}, { 'n', 'v' })
		keymap('<Leader>f', function()
			vim.lsp.buf.format { async = true }
		end, {})
  end
})

local timer = vim.loop.new_timer()
vim.api.nvim_create_autocmd("LspProgress", {
  group = lsp_group,
  callback = function()
    vim.cmd.redrawstatus()
    if timer then
      timer:stop()
      timer:start(500, 0, vim.schedule_wrap(function()
        timer:stop()
        vim.cmd.redrawstatus()
      end))
    end
  end
})

