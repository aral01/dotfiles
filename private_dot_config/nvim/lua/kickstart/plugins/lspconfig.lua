-- LSP Plugins (no Mason)
return {
  {
    -- Lua dev UX for your config/plugins
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- LSP core configs for 0.11+
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'j-hui/fidget.nvim', opts = {} }, -- LSP status
      'saghen/blink.cmp', -- completion
    },
    config = function()
      ---------------------------------------------------------------------------
      -- GLOBAL LSP DEFAULTS
      -- Merge blink.cmp capabilities into *all* servers (0.11 config merge).
      ---------------------------------------------------------------------------
      if vim.fn.has 'nvim-0.11' == 1 then
        vim.lsp.config('*', {
          capabilities = require('blink.cmp').get_lsp_capabilities(),
        })
      end

      ---------------------------------------------------------------------------
      -- KEYMAPS + UI when an LSP attaches
      ---------------------------------------------------------------------------
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
          map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

          ---@param client vim.lsp.Client
          ---@param method vim.lsp.protocol.Method
          ---@param bufnr? integer
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- Highlight references on CursorHold
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local hl = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = hl,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = hl,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(e)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = e.buf }
              end,
            })
          end

          -- Toggle inlay hints
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end

          -- Python: prefer Pyrefly for hover; keep Ruff for lint/format/imports
          if client and client.name == 'ruff' then
            client.server_capabilities.hoverProvider = false
          end
        end,
      })

      ---------------------------------------------------------------------------
      -- Diagnostics UI
      ---------------------------------------------------------------------------
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(d)
            return d.message
          end,
        },
      }

      ---------------------------------------------------------------------------
      -- Server-specific tweaks (0.11 style)
      -- You can extend any server like this before enabling it.
      ---------------------------------------------------------------------------

      -- Lua
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
          },
        },
      })

      -- Ruff (built-in LSP; requires ruff >= 0.5.3 if using latest lspconfig)
      -- No init_options needed unless you want to tune lint/format/imports.

      -- Pyrefly (new Python type checker + LSP)
      -- Default cmd: { 'pyrefly', 'lsp' }. Override via vim.lsp.config if needed.

      -- Clangd: defaults are fine. Supply compile_commands.json in project root.
      -- Example flags if you ever need them:
      -- vim.lsp.config('clangd', { cmd = { 'clangd', '--background-index' } })

      -- Rust Analyzer: defaults are fine. Configure via settings if desired.

      ---------------------------------------------------------------------------
      -- Enable servers (auto-attach by filetype/root markers)
      ---------------------------------------------------------------------------
      vim.lsp.enable {
        'lua_ls',
        'ruff',
        'pyrefly',
        'clangd',
        'rust_analyzer',
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
